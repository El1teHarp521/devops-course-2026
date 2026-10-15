#!/usr/bin/env bash
# Доставка статического ресурса на devops-vm
# Использование: scripts/deploy.sh [--dry-run]
set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
REPO_ROOT="$(git rev-parse --show-toplevel)"
LOCAL_DIR="${REPO_ROOT}/site/"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
fi

# Требование 4: проверка наличия site/index.html
if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "Ошибка: ${LOCAL_DIR}index.html не найден!" >&2
    exit 1
fi

# Требование 5: проверка незафиксированных изменений
if ! git diff-index --quiet HEAD --; then
    echo "Ошибка: в репозитории есть незафиксированные изменения!" >&2
    exit 1
fi

# Требование 3, 8, 9: Синхронизация rsync через SSH в BatchMode
rsync -avz --delete --chmod=D755,F644 \
    -e "ssh -o BatchMode=yes -o ConnectTimeout=5" \
    ${DRY_RUN} \
    "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}/"

# Требование 1: При --dry-run завершение с кодом 0 без проверки доступности
if [[ -n "${DRY_RUN}" ]]; then
    echo "Dry run завершен успешно."
    exit 0
fi

# Требование 6: Проверка доступности ресурса с проверкой сертификата
if ! curl -sf --cacert "${CA_CERT}" "${SITE_URL}" > /dev/null; then
    echo "Ошибка: ресурс ${SITE_URL} недоступен или ошибка сертификата!" >&2
    exit 1
fi

# Требование 7: Код возврата 0 с выводом короткого хеша коммита
COMMIT_HASH="$(git rev-parse --short HEAD)"
echo "Деплой успешно выполнен для коммита: ${COMMIT_HASH}"
exit 0
