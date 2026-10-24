# Docker 및 Singularity

[목차](../README.md)

## 현재 상태

| 항목 | 확인값 |
|---|---|
| Docker | 27.0.3; `docker`, `containerd` 실행 중 |
| Compose | v2.28.1; `docker compose` 사용 |
| Docker Root Dir | `/data/00_tools/docker` |
| 런타임 | `runc`, `io.containerd.runc.v2`; NVIDIA 런타임 등록은 확인되지 않음 |
| Singularity | `/usr/local/bin/singularity`, CE 4.1.0-rc.1+80-gb80afd568 |

Docker는 기존 컨테이너를 운영하고 있습니다. 데이터 경로 변경이나 서비스 재시작은 다른 작업에도 영향을 주므로 일반 사용 절차에 포함하지 않습니다.

## 조회 및 프로젝트 실행

Docker 사용 권한이 있는 계정에서 실행합니다.

```bash
docker version
docker compose version
docker info --format '{{.DockerRootDir}}'
docker ps
docker images
docker network ls
docker volume ls
docker stats --no-stream
docker system df
```

프로젝트에서 제공하는 Compose 파일이 있는 경우 해당 디렉터리에서 실행합니다.

```bash
docker compose config --quiet
docker compose ps
docker compose logs --tail=100
# 본인 프로젝트를 시작할 때만
docker compose up -d
```

비밀번호·토큰이 들어갈 수 있는 Compose 전체 설정이나 `docker inspect` 출력은 공개 문서에 붙이지 않습니다. 기존 컨테이너 일괄 중지·삭제, `docker system prune`, 전체 볼륨 정리는 공용 서버에서 기본 절차로 사용하지 않습니다.

## CPU와 메모리

새 컨테이너의 제한 예시입니다. `IMAGE`와 `COMMAND`는 본인 프로젝트에 맞게 바꿉니다.

```bash
docker run --rm --cpus=4 --memory=8g IMAGE COMMAND
```

Docker 자체 제한과 Slurm의 자원 예약은 서로 자동 연동되지 않습니다. Slurm 스크립트에서 Docker를 시작한다고 컨테이너가 Slurm의 CPU·GPU·종료 처리를 자동으로 따르는 것은 아닙니다.

## GPU

NVIDIA 드라이버와 CUDA는 설치돼 있지만 Docker NVIDIA 런타임·툴킷 구성은 확인되지 않았습니다. 따라서 `docker run --gpus all`이 현재 동작한다고 안내하지 않습니다.

현재 GPU 배치 작업은 [Slurm 예제](../examples/gpu.sbatch)를 기준으로 사용합니다. NVIDIA Container Toolkit 설치나 Docker 런타임 변경은 기존 컨테이너 영향을 검토한 후 별도 작업으로 진행합니다.

## Singularity

```bash
singularity --version
singularity inspect IMAGE.sif
singularity exec IMAGE.sif COMMAND
```

`IMAGE.sif`와 `COMMAND`는 실제 파일·명령으로 바꿉니다. 입력 데이터는 필요한 범위만 바인드합니다.

```bash
singularity exec --bind /data/PROJECT:/work IMAGE.sif COMMAND
```

GPU용 `--nv`는 이미지 내부 라이브러리와 호스트 드라이버의 호환성을 별도로 확인해야 합니다. 설치·버전은 확인했으나 개별 이미지의 GPU 실행은 검증하지 않았습니다.
