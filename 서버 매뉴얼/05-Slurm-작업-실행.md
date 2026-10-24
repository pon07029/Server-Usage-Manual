# Slurm 작업 실행

[목차](../README.md) · 현재 구성: 노드 `vbmi` 1개, 기본 파티션 `main`, A10 GPU 1개.

## 작업 제출 전

```bash
sinfo
squeue
free -h
nvidia-smi
pwd
```

`main`이 `up`이고 필요한 자원이 있어야 실행됩니다. Slurm 밖의 작업·컨테이너 사용량은 예약에 반영되지 않습니다. `idle`은 Slurm 예약이 없다는 뜻입니다. 서버 전체 사용량도 확인합니다.

- `-c` / `--cpus-per-task`: 작업당 CPU 요청. 프로그램의 스레드 수도 함께 지정합니다.
- `--mem`: 작업 전체 메모리 예약량. 현재 초과 사용을 강제 차단하지 않습니다.
- `--time`: 실행 시간 제한. 파티션 최대값은 무제한이지만 작업별로 필요한 시간을 지정합니다.
- `--gres=gpu:a10:1` 또는 `--gres=gpu:1`: GPU 1개 예약.
- `--nodes=1`: 단일 노드. GPU 2개 이상이나 여러 노드를 요청하는 예제는 이 서버에 적용되지 않습니다.

코어 단위로 할당하는 `CR_Core_Memory` 구성입니다. 하이퍼스레딩 때문에 CPU 요청이 전체 코어 단위로 반올림될 수 있습니다.

## 바로 실행하기

아래 `analysis.py`·`analysis.R`·`train.py`는 사용자가 준비한 프로그램입니다. 프로그램과 필요한 환경이 있는 디렉터리에서 제출합니다.

```bash
sbatch -p main -c 8 --mem=16G --time=02:00:00 --wrap="python3 analysis.py"
sbatch -p main -c 8 --mem=16G --time=02:00:00 --wrap="Rscript analysis.R"
sbatch -p main -c 8 --mem=16G --gres=gpu:a10:1 --time=02:00:00 --wrap="python3 train.py"
```

기본 출력은 제출 디렉터리의 `slurm-작업번호.out`입니다. `--wrap`은 기본적으로 `/bin/sh`로 실행되므로 Bash의 `source`가 필요하면 아래 배치 파일 방식을 사용합니다.

## 배치 파일과 실행 예제

저장소를 내려받은 디렉터리에서 실행합니다.

```bash
sbatch examples/cpu.sbatch
sbatch examples/gpu.sbatch
sbatch examples/array.sbatch
```

- [CPU 예제](../examples/cpu.sbatch): Python 실행 및 요청 스레드 환경변수 설정.
- [GPU 예제](../examples/gpu.sbatch): GPU 예약 후 장치·환경변수 확인. 학습 프레임워크는 요구하지 않음.
- [배열 예제](../examples/array.sbatch): 작업 3개, 최대 동시 2개. 출력 이름은 `%A_%a`로 분리.

예제는 작은 확인 작업입니다. 실제 분석으로 바꿀 때 `--mem`, CPU, 시간, 실행 명령을 수정합니다. `#SBATCH` 지시자는 셸 명령보다 앞에 두고 변수 확장을 기대하지 않습니다. 출력 경로에 하위 디렉터리를 지정하면 제출 전에 생성합니다.

개인 환경을 사용할 때는 실행 명령 앞에 명시합니다.

```bash
# 본인의 Conda 설치 및 환경에 맞게 수정
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate MYENV
python analysis.py

# 또는 본인 프로젝트 가상환경의 절대 경로 사용
/path/to/project/.venv/bin/python analysis.py
```

## 조회·취소

```bash
squeue -u "$USER"
scontrol show job JOBID
scontrol show node vbmi
sstat -j JOBID.batch --format=JobID,MaxRSS,AveCPU
tail -f slurm-JOBID.out
scancel JOBID
```

`sstat`는 실행 중인 작업의 표본 통계이며 짧은 작업에서는 비어 있을 수 있습니다. `squeue`의 `PD`는 대기, `R`은 실행, `CG`는 정리 중입니다. 종료 후에는 대기열에서 사라집니다.

현재 회계 DB가 없으므로 `sacct`·`sreport`로 영구 이력을 조회하는 구성이 아닙니다. 종료 직후에는 `scontrol show job JOBID`, 이후에는 출력 파일이나 관리자의 `/var/log/slurm/job-completion.log`를 확인합니다.

## 문제 해결

| 증상 | 확인 |
|---|---|
| `Could not establish a configuration source` | 이 서버에서 실행 중인지, `SLURM_CONF`가 오래된 경로를 가리키는지 확인 |
| 작업이 대기 | `squeue`의 이유와 `scontrol show job JOBID`; 자원·GPU·노드 요청 확인 |
| Python/Conda/명령을 못 찾음 | 배치에서 환경 초기화 또는 절대 경로 사용 |
| 출력 파일이 없음 | 출력 경로 권한·디렉터리 존재, 작업이 시작됐는지 확인 |
| GPU 사용이 충돌함 | Slurm 밖에서 GPU를 쓰는 프로세스도 `nvidia-smi`로 확인 |
| 메모리 부족 / 프로세스 종료 | 실제 사용량·커널 OOM 로그를 관리자와 확인; `--mem`만으로 강제 격리되지 않음 |

GPU 장치 접근과 메모리 초과 사용은 현재 cgroup으로 강제 제한하지 않습니다. Slurm 밖에서 실행 중인 작업이 자동으로 편입되거나 종료되는 것도 아닙니다.
