# System Monitor

Учебный проект по системному администрированию Linux.

Проект включает Bash-мониторинг ресурсов, контейнеризацию с Docker, настройку RAID 1 и LVM, HTTP-сервис за Nginx reverse proxy с TLS и управление приложением через systemd.

## 1. Bash-мониторинг

Скрипт `script.sh` периодически собирает:

- Текущую дату и время.
- Время работы системы (uptime).
- Информацию об оперативной памяти.
- Информацию о дисковом пространстве.

Результаты записываются в `monitor.log`.

### Запуск

```bash
chmod +x script.sh
./script.sh 5
```

Интервал указывается в секундах. По умолчанию используется 5 секунд.

Скрипт проверяет корректность интервала. Для остановки нажмите `Ctrl+C`.

## 2. Docker и Docker Compose

Для контейнеризации используется `Dockerfile` на основе Ubuntu 22.04.

Контейнер запускает два процесса:

- Bash-скрипт, записывающий результаты мониторинга.
- Python HTTP-сервер, предоставляющий доступ к файлу `monitor.log`.

HTTP-сервер работает на порту `8080`.

### Запуск

Необходимы Docker Engine и Docker Compose V2.

```bash
docker volume create monitor-data
docker compose up -d --build
```

Проверка:

```bash
docker compose ps
curl -I http://127.0.0.1:8080/monitor.log
```

Ожидаемый HTTP-статус: `200 OK`.

Docker volume `monitor-data` сохраняет журнал мониторинга при пересоздании контейнера.

Порт `8080` опубликован только на `127.0.0.1` хостовой системы.

## 3. RAID 1 и LVM

Для практики управления хранилищами используются три файла-образа размером 512 МиБ, подключённые как loop-устройства.

### RAID 1

Из двух loop-устройств создан зеркальный RAID-массив:

- Устройство: `/dev/md0`.
- Уровень RAID: 1.
- Файловая система: ext4.
- Точка монтирования: `/mnt/raid`.

Проверка:

```bash
cat /proc/mdstat
df -h /mnt/raid
```

Состояние `[UU]` означает, что оба устройства RAID 1 активны.

### LVM

Третье loop-устройство используется для LVM:

- Physical Volume: `/dev/loop8`.
- Volume Group: `vg_data`.
- Logical Volume: `lv_logs`.
- Размер LV: 200 МиБ.
- Файловая система: ext4.
- Точка монтирования: `/mnt/logs`.

Проверка:

```bash
sudo pvs
sudo vgs
sudo lvs
df -h /mnt/logs
```

RAID и LVM настроены в учебной виртуальной машине. Автоматическое восстановление loop-устройств и монтирования после перезагрузки отдельно не реализовано.

## 4. Nginx Reverse Proxy

Nginx установлен непосредственно в Ubuntu и перенаправляет запросы на HTTP-сервер Docker-контейнера.

Схема:

```text
Client
  |
  | HTTPS :443
  v
Nginx
  |
  | HTTP :8080
  v
Docker container
  |
  v
Python HTTP Server
  |
  v
monitor.log
```

Конфигурация Nginx находится в `deploy/nginx.conf`.

При развёртывании она устанавливается в `/etc/nginx/sites-available/my-app` и активируется через `sites-enabled`.

## 5. HTTPS / TLS

Для HTTPS используется самоподписанный TLS-сертификат.

Создание сертификата:

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/my-app.key \
  -out /etc/ssl/certs/my-app.crt \
  -subj "/CN=my-app.local"
```

Сертификат хранится в `/etc/ssl/certs/my-app.crt`, приватный ключ — в `/etc/ssl/private/my-app.key`.

Приватный ключ не включён в Git-репозиторий.

Nginx принимает HTTPS-запросы на порту `443`, а HTTP-запросы на порту `80` перенаправляет на HTTPS с кодом `301`.

Проверка:

```bash
sudo nginx -t
curl -kI https://127.0.0.1/monitor.log
```

Ожидаемый статус: `200 OK`.

Параметр `-k` отключает проверку доверия к сертификату и используется только для учебного тестирования. Самоподписанный сертификат не обеспечивает автоматическую проверку подлинности сервера.

## 6. Systemd

Для управления контейнером используется служба `my-app.service`.

Unit-файл находится в `deploy/my-app.service` и устанавливается в `/etc/systemd/system/my-app.service`.

В учебной конфигурации рабочий каталог службы:

`/home/ubuntu/my-sysadmin-scripts`

При развёртывании в другом каталоге путь необходимо изменить.

### Управление

```bash
sudo systemctl daemon-reload
sudo systemctl enable my-app
sudo systemctl start my-app
sudo systemctl stop my-app
sudo systemctl status my-app
```

Просмотр журнала:

```bash
sudo journalctl -u my-app --no-pager -n 30
```

Служба использует `Type=oneshot` и `RemainAfterExit=yes`, поэтому после успешного запуска контейнера отображается состояние `active (exited)`.

Фактическое состояние контейнера проверяется отдельно:

```bash
docker compose ps
```

## 7. Структура проекта

```text
my-sysadmin-scripts/
├── script.sh
├── Dockerfile
├── docker-compose.yml
├── README.md
├── sample_output.txt
└── deploy/
    ├── nginx.conf
    └── my-app.service
```

## 8. Окружение

Проект выполнен в виртуальной машине Ubuntu 22.04 LTS.

Использованные инструменты:

- Bash
- Git и GitHub
- Docker и Docker Compose
- mdadm
- LVM2
- Nginx
- OpenSSL
- systemd
- Python 3

Проект предназначен для обучения и демонстрации базовых навыков администрирования Linux.
