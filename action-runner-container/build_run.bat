@echo off
setlocal enabledelayedexpansion

:: Usage: build_run.bat ^<RUNNER_URL^> ^<RUNNER_TOKEN^> [IMAGE_TAG] [RUNNER_NAME] [REGISTRY]
if "%~1"=="" (
    echo Usage: %~nx0 ^<RUNNER_URL^> ^<RUNNER_TOKEN^> [IMAGE_TAG] [RUNNER_NAME] [REGISTRY]
    exit /b 1
)

set "RUNNER_URL=%~1"
set "RUNNER_TOKEN=%~2"
set "IMAGE_TAG=%~3"
if "%IMAGE_TAG%"=="" set "IMAGE_TAG=action-runner:latest"
set "RUNNER_NAME=%~4"
set "REGISTRY=%~5"

if "%RUNNER_TOKEN%"=="" (
    echo Error: RUNNER_TOKEN is required (pass as argument)
    exit /b 1
)

echo Building Docker image: %IMAGE_TAG%
docker build --build-arg RUNNER_TOKEN=%RUNNER_TOKEN% --build-arg RUNNER_URL=%RUNNER_URL% --build-arg RUNNER_NAME=%RUNNER_NAME% -t %IMAGE_TAG% .

if not "%REGISTRY%"=="" (
    set "FULL_TAG=%REGISTRY%/%IMAGE_TAG%"
    echo Tagging image as %FULL_TAG% and pushing
    docker tag %IMAGE_TAG% %FULL_TAG%
    docker push %FULL_TAG%
    set "IMAGE_TAG=%FULL_TAG%"
)

echo Running container (mounts host podman socket at /run/podman/podman.sock)
echo Command hint: docker run -v /run/podman/podman.sock:/run/podman/podman.sock %IMAGE_TAG%

docker run -d ^
  --name action-runner ^
  --restart unless-stopped ^
  -v /run/podman/podman.sock:/run/podman/podman.sock ^
  %IMAGE_TAG%

echo Container started successfully!
