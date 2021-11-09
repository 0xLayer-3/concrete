#!/bin/bash -e

set -e

BASE_IMG_ENDPOINT_URL=
ENV_IMG_ENDPOINT_URL=
TOKEN=
ENV_DOCKERFILE=./docker/Dockerfile.concretefhe-env
GITHUB_ENV_FILE=

while [ -n "$1" ]
do
   case "$1" in
        "--base_img_url" )
            shift
            BASE_IMG_ENDPOINT_URL="$1"
            ;;

        "--env_img_url" )
            shift
            ENV_IMG_ENDPOINT_URL="$1"
            ;;

        "--token" )
            shift
            TOKEN="$1"
            ;;

        "--github-env")
            shift
            GITHUB_ENV_FILE="$1"
            ;;

        *)
            echo "Unknown param : $1"
            exit 1
            ;;
   esac
   shift
done

BASE_JSON=$(curl \
-X GET \
-H "Accept: application/vnd.github.v3+json" \
-H "Authorization: token ${TOKEN}" \
"${BASE_IMG_ENDPOINT_URL}")

LATEST_BASE_IMG_JSON=$(echo "${BASE_JSON}" | jq -rc 'sort_by(.updated_at)[-1]')

echo "Latest base image json: ${LATEST_BASE_IMG_JSON}"

BASE_IMG_TIMESTAMP=$(echo "${LATEST_BASE_IMG_JSON}" | jq -r '.updated_at')

ENV_JSON=$(curl \
-X GET \
-H "Accept: application/vnd.github.v3+json" \
-H "Authorization: token ${TOKEN}" \
"${ENV_IMG_ENDPOINT_URL}")

ENV_IMG_TIMESTAMP=$(echo "${ENV_JSON}" | \
jq -rc '.[] | select(.metadata.container.tags[] | contains("latest")).updated_at')

echo "Base timestamp: ${BASE_IMG_TIMESTAMP}"
echo "Env timestamp:  ${ENV_IMG_TIMESTAMP}"

BASE_IMG_DATE=$(date -d "${BASE_IMG_TIMESTAMP}" +%s)
ENV_IMG_DATE=$(date -d "${ENV_IMG_TIMESTAMP}" +%s)

echo "Base epoch: ${BASE_IMG_DATE}"
echo "Env epoch:  ${ENV_IMG_DATE}"

if [[ "${BASE_IMG_DATE}" -ge "${ENV_IMG_DATE}" ]]; then
    echo "Env image out of date, sending rebuild request."
    NEW_BASE_IMG_TAG=$(echo "${LATEST_BASE_IMG_JSON}" | \
    jq -rc '.metadata.container.tags - ["latest"] | .[0]')
    echo "NEW_BASE_IMG_TAG=${NEW_BASE_IMG_TAG}" >> "${GITHUB_ENV_FILE}"
    echo "New base img tag: ${NEW_BASE_IMG_TAG}"
    TMP_DOCKER_FILE="$(mktemp)"
    sed "s/\(FROM\ ghcr\.io\/zama-ai\/zamalang-compiler:\)\(.*\)/\1${NEW_BASE_IMG_TAG}/g" \
        "${ENV_DOCKERFILE}" > "${TMP_DOCKER_FILE}"
    cp -f "${TMP_DOCKER_FILE}" "${ENV_DOCKERFILE}"
    rm -f "${TMP_DOCKER_FILE}"
else
    echo "Image up to date, nothing to do."
fi
