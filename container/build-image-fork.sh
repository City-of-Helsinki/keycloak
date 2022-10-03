# #!/usr/bin/env bash

set -e
set -o pipefail


function info {
    echo "$@" 1>&2
}

function fatal {
    echo "$@" 1>&2
    exit 1
}

function determine_docker_executable {
    for CANDIDATE in docker podman; do
        $CANDIDATE --version &> /dev/null || continue
        echo $CANDIDATE
        return 0
    done

    return 1
}

function is_azure_pipeline {
    # Azure pipelines set certain environment variables.
    # Use them to guess if executing in an Azure pipeline.
    test -d "$PIPELINE_WORKSPACE"
    return $?
}


cd "$(dirname -- $0)"

DOCKER_BIN=$(determine_docker_executable) || fatal "No Docker/Podman executable found"
info "Using $DOCKER_BIN"


# THEME_COMMIT_ID='93e4f6d'
# PLUGIN_COMMIT_ID=$(git rev-parse --short HEAD)


# Build plugin
# pushd ..
# ./gradlew --info installDist
# popd


# Get theme
# rm -rf helsinki-keycloak-theme
# git clone https://github.com/City-of-Helsinki/helsinki-keycloak-theme.git --progress --branch master
# pushd helsinki-keycloak-theme
# git checkout $THEME_COMMIT_ID
# echo $THEME_COMMIT_ID > helsinki/version.txt
# popd


# Determine version
# KEYCLOAK_VERSION=$(grep -m1 -E "^ARG KEYCLOAK_VERSION=[0-9\.]+" Dockerfile | cut -d'=' -f2)
# KEYCLOAK_IMAGE_VERSION=${KEYCLOAK_VERSION}_plugin_${PLUGIN_COMMIT_ID}_theme_${THEME_COMMIT_ID}

# Need to copy some files to other directories so that they are found as
# expected by Dockerfile
# rm -rf providers
# mkdir providers
# cp ../plugin-module/build/install/plugin-module/* providers
# pushd ..
# mvn clean install
# popd

FORK_COMMIT_ID=$(git rev-parse --short HEAD)

# Build image
$DOCKER_BIN build \
	  --build-arg GITHUB_REPO="City-of-Helsinki/keycloak" \
	  --build-arg GITHUB_BRANCH="19.0" \
    --tag helsinki/helsinki-keycloak:19.0-helsinki-${FORK_COMMIT_ID} \
    --tag helsinki/helsinki-keycloak:latest \
    .


if (is_azure_pipeline); then
  echo "##vso[task.setvariable variable=keycloakImage]19.0-helsinki-${FORK_COMMIT_ID}"
  # echo "##vso[task.setvariable variable=keycloakImage]${KEYCLOAK_IMAGE_VERSION}"
fi