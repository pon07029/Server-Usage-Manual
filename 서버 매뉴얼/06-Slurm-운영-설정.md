# Slurm 운영 설정

[목차](../README.md) · 관리자용. 2026-10-24 실측 설정입니다.

## 구성과 경로

`slurm-client`, `slurmctld`, `slurmd` 21.08.5와 Munge를 사용합니다. 컨트롤러와 실행 데몬이 모두 `vbmi`에서 동작합니다.

| 항목 | 경로 / 값 |
|---|---|
| 기본 설정 | `/etc/slurm/slurm.conf` |
| GPU 설정 | `/etc/slurm/gres.conf` |
| 컨트롤러 상태 | `/var/spool/slurmctld-vbmi` (slurm 소유) |
| 실행 데몬 상태 | `/var/spool/slurmd-vbmi` (root 소유) |
| 서비스 로그 | `/var/log/slurm/slurmctld.log`, `slurmd.log` |
| 완료 이력 | `/var/log/slurm/job-completion.log` |
| 파티션 | `main`, 기본값, 최대 실행시간 무제한 |
| 기본 메모리 | 요청 CPU당 2048MB; 실제 분석은 `--mem` 명시 권장 |
| 자원 선택 | `select/cons_tres`, `CR_Core_Memory` |
| 추적 / CPU 바인딩 | `proctrack/linuxproc` / `task/affinity` |
| 회계 DB / QoS | 회계 저장 없음, DB 기반 QoS 미구성 |

`/etc/slurm-llnl`과 이전 `/var/spool/slurmctld`, `/var/spool/slurmd`도 남아 있지만 현행 상태 저장소로 사용하지 않습니다. 이전 컨트롤러 상태는 다른 클러스터 이름 `cluster`로 생성돼 있어 새 상태 디렉터리로 분리했습니다. 이전 파일을 삭제해 충돌을 해결하지 않습니다. 변경 전 설정은 `/root/slurm-backup-20261024-162331`에 보관했습니다.

## 실제 slurm.conf

아래는 확인 당시의 설정입니다. 기존 서버 설정을 덮어쓰는 설치 스크립트가 아닙니다.

```ini
ClusterName=vbmi
SlurmctldHost=vbmi(127.0.0.1)
SlurmUser=slurm
SlurmdUser=root
AuthType=auth/munge
StateSaveLocation=/var/spool/slurmctld-vbmi
SlurmdSpoolDir=/var/spool/slurmd-vbmi
SlurmctldPidFile=/run/slurmctld.pid
SlurmdPidFile=/run/slurmd.pid
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdLogFile=/var/log/slurm/slurmd.log
ReturnToService=2
ProctrackType=proctrack/linuxproc
TaskPlugin=task/affinity
JobAcctGatherType=jobacct_gather/linux
JobAcctGatherFrequency=30
AccountingStorageType=accounting_storage/none
JobCompType=jobcomp/filetxt
JobCompLoc=/var/log/slurm/job-completion.log
SchedulerType=sched/backfill
SelectType=select/cons_tres
SelectTypeParameters=CR_Core_Memory
GresTypes=gpu
NodeName=vbmi NodeAddr=127.0.0.1 CPUs=128 Boards=1 SocketsPerBoard=2 CoresPerSocket=32 ThreadsPerCore=2 RealMemory=950000 Gres=gpu:a10:1 State=UNKNOWN
PartitionName=main Nodes=vbmi Default=YES MaxTime=INFINITE State=UP DefMemPerCPU=2048 OverSubscribe=NO
```

실제 `gres.conf`는 다음 한 줄입니다.

```ini
NodeName=vbmi Name=gpu Type=a10 File=/dev/nvidia0
```

연결 대상은 127.0.0.1로 지정했지만 데몬의 수신 범위를 루프백으로 제한하는 설정은 아닙니다. 확인 당시 6817/6818은 전체 IPv4 주소에서 수신 중이었습니다. 외부 노드를 추가할 때는 인증·네트워크·방화벽을 별도로 설계합니다.

## 상태 확인

```bash
sbatch --version
sudo slurmd -C
scontrol ping
sinfo -N -l
scontrol show node vbmi
systemctl is-active munge slurmctld slurmd
systemctl is-enabled munge slurmctld slurmd
sudo journalctl -u slurmctld -u slurmd -n 80 --no-pager
sudo tail -n 20 /var/log/slurm/job-completion.log
```

`scontrol ping`이 UP이고 노드를 사용할 수 있는지 확인합니다. 장애 시 원인을 확인하지 않고 노드를 RESUME하거나 상태 파일을 지우지 않습니다.

## cgroup 및 운영상 제한

호스트는 cgroup v2지만 설치된 21.08.5의 cgroup 플러그인은 v1입니다. 따라서 현행 구성은 `task/affinity`와 `proctrack/linuxproc`를 사용합니다.

- 메모리는 스케줄러상 예약이며 초과 사용을 강제 중단하지 않습니다.
- GPU 예약·가시성 변수는 설정하지만 장치 접근을 cgroup으로 차단하지 않습니다.
- 이전 `cgroup.conf`에 `ConstrainRAMSpace=yes` 등이 있어도 현행 플러그인 구성에서 해당 제약이 활성화되는 것은 아닙니다.
- Slurm 외의 기존 분석·Docker·RStudio·웹 서비스 사용량은 자동 집계되지 않습니다.
- `slurmdbd`, DB 계정, QoS 및 장기 `sacct` 통계는 미구성입니다.

메모리·장치의 강제 격리가 필요하면 cgroup v2를 지원하는 Slurm 업데이트를 별도로 검토합니다. 기존 분석 중단이나 OS의 cgroup 방식 변경은 이번 작업에서 수행하지 않았습니다.
