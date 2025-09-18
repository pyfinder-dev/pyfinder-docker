# pyfinder: FinDer + ShakeMap + PyFinder 

[![Docker](https://img.shields.io/badge/docker-ready-blue)](#)
[![License](https://img.shields.io/badge/license-see%20LICENSE-green)](./LICENSE)

This repository was initially developed under the [DT-GEO project](https://dtgeo.eu) as part of the [DTC-E6 component](https://github.com/DT-Geo-SED-ETHZ/DTC-E6), which provided offline **playback** functionality for earthquake early warning workflows. The current repository is an independent, clean replica focusing exclusively on the *Workflow-2* using **PyFinder**, providing a Dockerized environment to run **FinDer**, **ShakeMap**, and **PyFinder** for EEW workflows. Future developments continue here.

---

## Contents
- [Requirements](#requirements)
- [Quickstart](#quickstart)
- [Build](#build)
- [Run](#run)
- [Mounted Volumes & Outputs](#mounted-volumes--outputs)
- [Playbacks](#playbacks)
- [Repo Structure](#repo-structure)
- [Troubleshooting](#troubleshooting)
- [Notes & Licensing](#notes--licensing)

---

## Requirements
- **Docker** (Linux/macOS; Windows via WSL2 also works)
- **Git**
- Optional: **GitHub Container Registry** login (`docker login ghcr.io`) if you push/pull private images

Hardware: 
- ≥ 4 CPU cores and ≥ 4 GB RAM recommended

---

## Quickstart

```bash
# 1) Clone
git clone https://github.com/pyfinder-dev/pyfinder-docker
cd pyfinder-docker

# 2) Build the image
./docker_build.sh

# 3) Start the container (post_start_setup must be run manually)
./docker_run_op.sh

# or, if you are a developer (note that mount paths might need adjustment dependng on your local setup)
./docker_run_dev.sh
```

---

## Build

Use the helper script; it is **OS-smart**:

```bash
./docker_build.sh
```

- On Apple Silicon (macOS arm64), it automatically uses **buildx** with `--platform linux/amd64`.
- On Linux/x86_64, it uses plain `docker build`.

**Environment overrides** (optional):
- `DOCKERFILE` — Dockerfile path (default: `Dockerfile`)
- `IMAGE_TAG` — Image tag (default: `pyfinderdocker:master`)
- `BUILD_CONTEXT` — Build context (default: `.`)
- `FORCE_BUILDX=true` — Force buildx on any system
- `FORCE_PLATFORM=linux/amd64` — Force target platform (implies buildx)

Examples:
```bash
FORCE_PLATFORM=linux/amd64 ./docker_build.sh
IMAGE_TAG=myrepo/pyfinderdocker:test DOCKERFILE=Dockerfile.myversion ./docker_build.sh
```

---

## Run

Start the container using the run helper:

```bash
./docker_run_op.sh
```

If you are actively developing, you will probably want to mount your own source code 
paths inside the container. Then use:

```bash
./docker_run_dev.sh
```

Both of these scripts will
1. Stop/remove any existing `pyfinder` container.
2. Prepare host-side output directories under `host_shared/docker-output/`.
3. Launch the container with all required **volume mappings** and environment settings.

> After the container is started, you must manually run the post-start setup script inside the container:

```bash
docker exec -it pyfinderdocker bash
/home/sysop/host_shared/post_start_setup.sh
```

> Make sure your post-start script exists and is executable on the host:
> ```bash
> chmod +x host_shared/post_start_setup.sh
> ```

---

## Mounted Volumes & Outputs

All important paths are mounted back to the **host** so you can inspect results without entering the container:

- **FinDer outputs** → `host_shared/docker-output/FinDer-output/`
- **ShakeMap outputs** → `host_shared/docker-output/shakemap/`
- **PyFinder outputs** → also goes to `host_shared/docker-output/shakemap/` and `host_shared/docker-output/FinDer-output/`

These directories persist even if you remove the container.

And for `dev` version, these paths will be mounted from you localhost (in addition to the ones above):

- **pyfinder** → `../pyfinder` as `/home/sysop/pyfinder` inside the container
- **paramws-clients** → `../paramws-clients` as `/home/sysop/paramws-clients` inside the container

---

## Playbacks

Enter the container and run PyFinder’s playback with **Python 3.9**:
```bash
docker exec -it pyfinderdocker bash
cd /home/sysop/pyfinder/pyfinder
python3.9 playback.py --event-id 20161030_0000029
```

   > **Note:** PyFinder follows RRSM update schedule from 5 minutes to 48 hours after an earthquake. If you wait long enough, it will submit all pre-scheduled update times into the database and follow them up. This does not change the final outcome since the playback emulates real-time data flow. Otherwise, feel free to break the process with `CTRL+C` after first iteration is completed. If you don't use `--event-id`, PyFinder will submit jobs for all predefined events in `playback.py`.

Outputs appear in `host_shared/docker-output/shakemap/` and `host_shared/docker-output/PyFinder-output`. You can tell apart PyFinder shakemap solutions by its name `<event-id><scheduled iteration>`, e.g. `20161030_0000029_t00000`.
Output files and logs can be collected from the host side from the mounted volumes. No need to copy from the container.

---

## Repo Structure

```
docker_build.sh                   # OS-smart build helper (buildx on Apple Silicon)
docker_run.sh                     # Start helper; sets up volumes and starts container
host_shared/
├─ post_start_setup.sh            # Manual post-start setup script (run inside container after start)
├─ playback.sh                    # (Optional) helper scripts for playback
├─ docker-output/
│  ├─ FinDer-output/              # FinDer results (host)
│  ├─ shakemap/                   # ShakeMap results (host)
│  └─ PyFinder-output/            # PyFinder results (host)
└─ docker_overrides/
   └─ shakemap_patches/           # Local ShakeMap patches (copied during build)
README.md                         # This file
```

---

## Notes & Licensing

- **FinDer** is **not open-source**. The image includes it for internal evaluation; do not redistribute binaries.
- See [LICENSE](./LICENSE) and [DISCLAIMER](./DISCLAIMER.md) for terms and exceptions.
