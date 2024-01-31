# POSTGRES BACKUP TO MINIO

This service lets yourpostgres database to minio

## Compatibility
Service can run on :
- amd64
- arm64v8

## Versions 
- For postgres 12: use tags 12.X
- For postgres 15: use tags 15.X

## Environments Variables
| Environments variables        | Default      | Description                                                                                                             | Mandatory / Optionnal |
|-------------------------------|--------------|-------------------------------------------------------------------------------------------------------------------------|-----------------------|
| MINIO_ACCESS_KEY_ID_FILE      | None         | Access Key for the bucker                                                                                               | **Mandatory**         |
| MINIO_SECRET_ACCESS_KEY_FILE  | None         | Secret Key for the bucket                                                                                               | **Mandatory**         |
| MINIO_REGION                  | None         | Minio Region                                                                                                            | **Mandatory**         |
| MINIO_ALIAS                   | None         | Alias for the mc co,mand                                                                                                | **Mandatory**         |
| MINIO_HOSTNAME                | None         | Hostname of Minio (ex: https://myminio.domain.tld)                                                                      | **Mandatory**         |
| MINIO_BUCKET                  | None         | Name of the bucket for uploading the dump                                                                               | **Mandatory**         |
| MINIO_TAGS                    | None         | Add tags for minio (ex: myservice=backup)                                                                               | Optionnal             |
| MINIO_SUBDIRECTORY            | None         | Subdirectory (For upload to backups/myservice just enter the subdirectory without backup name)                          | Optionnal             |
| MINIO_ATTRIBUTES              | None         | Options for minion command                                                                                              | Optionnal             |
| BACKUP_DIR                    | None         | Dump directory                                                                                                          | **Mandatory**         |
| POSTGRES_HOST                 | None         | Database hostnmae                                                                                                       | **Mandatory**         |
| POSTGRES_USER                 | None         | Database user  (you can use _FILE for the secret)                                                                       | **Mandatory**         |
| POSTGRES_PASSWD               | None         | Database Password  (you can use _FILE for the secret)                                                                   | **Mandatory**         |
| POSTGRES_DATABASE             | None         | Database name (you can use _FILE for the secret)                                                                        | **Mandatory**         |
| POSTGRES_SPLIT_TABLE_AND_DATA | False        | Slip schema and datas in two files                                                                                      | Optionnal             |
| POSTGRES_EXCLUDE_TABLE        | Empty String | Exclude export datas from table pattern. Empty String exports all datas                                                 | Optionnal             |
| POSTGRES_DUMP_FORMAT          | plain        | Format to export data. Values : plain, custom, directory, tar (https://www.postgresql.org/docs/current/app-pgdump.html) | Optionnal             |
| SCHEDULE                      | None         | Cron expression for schedule                                                                                            | **Mandatory**         |

## Secrets
You can use secret file for POSTGRES_USER, POSTGRES_PASSWD_FILE, POSTGRES_DATABASE_FILE
                                                                                                      
## Modes

### Backup
2 backup modes are available

#### Cron mode (Default)

You can start the container in cron mode

**CLI**
```
docker run -dit -e MINIO_ACCESS_KEY_ID_FILE=$[YOUR_MINIO_ACCESS_KEY_ID_FILE} /
    -e MINIO_SECRET_ACCESS_KEY_FILE=$[YOUR_MINIO_SECRET_ACCESS_KEY_FILE} /
    -e MINIO_REGION=$[YOUR_MINIO_REGION} /
    -e MINIO_ALIAS=$[YOUR_MINIO_ALIAS} /
    -e MINIO_HOSTNAME=$[YOUR_MINIO_HOSTNAMEE} /
    -e MINIO_BUCKET=$[YOUR_MINIO_BUCKET} /
    -e BACKUP_DIR=$[YOUR_BACKUP_DIR} /
    -e POSTGRES_USER=$[YOUR_POSTGRES_USER} /
    -e POSTGRES_HOST=$[YOUR_POSTGRES_HOST} /
    -e POSTGRES_PASSWD=$[YOUR_POSTGRES_PASSWD} /
    -e POSTGRES_DATABASE=$[YOUR_POSTGRES_DATABASE} /
    -e SCHEDULE=$[YOUR_SCHEDULE} /
    sgoubaud/backup-files-minio:latest

or

docker run -dit --env-file ./env.file sgoubaud/backup-files-minio:latest

```

**Docker compose**
```
  ---
  version: "3.9"

  backup:
    image: sgoubaud/backup-files-minio:latest
    networks:
      - your_network # if needed
    volumes:
      - type: volume
        source: data
        target: /my/target/directory # directory or file
        read_only: true # need to be false if you want to restore data
        volume:
          nocopy: true
      - backup:${BACKUP_DIR}
    environment:
      - MINIO_ACCESS_KEY_ID_FILE=/run/secrets/MINIO_BACKUP_ACCESS_KEY_ID
      - MINIO_SECRET_ACCESS_KEY_FILE=/run/secrets/MINIO_BACKUP_SECRET_ACCESS_KEY
      - MINIO_REGION=${MINIO_REGION}
      - MINIO_ALIAS=${MINIO_ALIAS}
      - MINIO_HOSTNAME=${MINIO_HOSTNAME}
      - MINIO_SUBDIRECTORY=${MINIO_SUBDIRECTORY}
      - MINIO_BUCKET=${MINIO_BUCKET}
      - MINIO_TAGS=${MINIO_TAGS}
      - BACKUP_DIR=${BACKUP_DIR}
      - BACKUP_NAME=${BACKUP_NAME}
      - FILES_PATH=${FILES_PATH}
      - SCHEDULE=${SCHEDULE}
    secrets:
      - MINIO_BACKUP_ACCESS_KEY_ID
      - MINIO_BACKUP_SECRET_ACCESS_KEY

secrets:
  MINIO_BACKUP_ACCESS_KEY_ID:
    external :true
  MINIO_BACKUP_SECRET_ACCESS_KEY:
    external :true
```

#### Single backup mode
```
docker run -dit -e MINIO_ACCESS_KEY_ID_FILE=$[YOUR_MINIO_ACCESS_KEY_ID_FILE} /
    -e MINIO_SECRET_ACCESS_KEY_FILE=$[YOUR_MINIO_SECRET_ACCESS_KEY_FILE} /
    -e MINIO_REGION=$[YOUR_MINIO_REGION} /
    -e MINIO_ALIAS=$[YOUR_MINIO_ALIAS} /
    -e MINIO_HOSTNAME=$[YOUR_MINIO_HOSTNAMEE} /
    -e MINIO_BUCKET=$[YOUR_MINIO_BUCKET} /
    -e BACKUP_DIR=$[YOUR_BACKUP_DIR} /
    -e POSTGRES_USER=$[YOUR_POSTGRES_USER} /
    -e POSTGRES_HOST=$[YOUR_POSTGRES_HOST} /
    -e POSTGRES_PASSWD=$[YOUR_POSTGRES_PASSWD} /
    -e POSTGRES_DATABASE=$[YOUR_POSTGRES_DATABASE} /
    -e SCHEDULE=$[YOUR_SCHEDULE} /
    sgoubaud/backup-files-minio:latest backup.sh

or

docker run -dit --env-file ./env.file sgoubaud/backup-files-minio:latest backup.sh

```

