# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины
- Память: 2048 МБ
- Процессоры: 2 ядра
- Диск: 25 ГБ (динамически расширяемый)

## 2. Сетевые интерфейсы
- Сетевой адаптер 1 (NAT): 10.0.2.15 (доступ в Интернет)
- Сетевой адаптер 2 (Host-only): 192.168.56.102 (прямой доступ с хостовой системы)

## 3. Правило проброса портов
- Правило `ssh`: порт хоста 2222 -> порт гостя 2222 (протокол TCP)

## 4. Учётные записи
- `student`: системная учётная запись, группа sudo, парольная аутентификация
- `devops`: административная учётная запись, группа sudo, аутентификация исключительно по ключу ed25519

## 5. Служба SSH
- Порт: 2222
- Расположение файла конфигурации: `/etc/ssh/sshd_config.d/99-hardening.conf`
- Ключевые директивы:
  - `PermitRootLogin no` (запрет входа root)
  - `PasswordAuthentication no` (отключение паролей)
  - `PubkeyAuthentication yes` (вход по ключу)
  - `MaxAuthTries 3` (максимум 3 попытки)
  - `AllowUsers devops` (доступ только пользователю devops)

## 6. Правила межсетевого экрана
- Политики по умолчанию: `default deny incoming`, `default allow outgoing`
- Активные правила:
  - `2222/tcp (LIMIT)` — SSH с ограничением частоты запросов
  - `80/tcp (ALLOW)` — HTTP для будущей работы с веб-сервером
  - `443/tcp (ALLOW)` — HTTPS

## 7. Снимки состояния
- `01-clean-install` — исходная чистая установка Ubuntu Server
- `02-keys-configured` — создана учётная запись devops, настроен вход по ключу
- `03-ssh-hardened` — служба SSH переведена на порт 2222, отключены пароли, настроен UFW
## 8. Веб-сервер
- Устанавливаемый пакет: `nginx`
- Путь к конфигурации ресурса: `/etc/nginx/sites-available/devops-site` (активирован через симлинк в `/etc/nginx/sites-enabled/`)
- Каталог ресурса: `/var/www/devops-site`, владелец `devops:devops`, права `755` для каталогов и `644` для файлов
- Пути к сертификату и ключу:
  - Сертификат: `/etc/ssl/certs/devops.crt` (права 644, владелец root)
  - Закрытый ключ: `/etc/ssl/private/devops.key` (права 600, владелец root)
- Команда формирования сертификата: `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/devops.key -out /etc/ssl/certs/devops.crt -subj "/CN=devops.local" -addext "subjectAltName=DNS:devops.local"`
- Срок действия: 365 дней (1 год)
