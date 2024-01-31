#!/usr/bin/env bash
# vim: set noexpandtab ts=4 sw=4 nolist:
set -Eeo pipefail

if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
        POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
        POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
fi

if [ -z "${POSTGRES_PORT}" ]; then
        POSTGRES_PORT=5432
fi

mkdir -p ${BACKUP_DIR}

if [[ -f ${POSTGRES_USER_FILE} ]] ; then
    export POSTGRES_USER=$(cat $POSTGRES_USER_FILE)
fi

if [[ -f ${POSTGRES_PASSWD_FILE} ]]; then
    export POSTGRES_PASSWD=$(cat $POSTGRES_PASSWD_FILE)
fi

if [[ -f ${POSTGRES_DATABASE_FILE} ]] ; then
    export POSTGRES_DATABASE=$(cat $POSTGRES_DATABASE_FILE)
fi

# env vars needed for minio tools
export MINIO_ACCESS_KEY_ID=$MINIO_ACCESS_KEY_ID
if [[ -f ${MINIO_ACCESS_KEY_ID_FILE} ]] ; then             
    export MINIO_ACCESS_KEY_ID=$(cat $MINIO_ACCESS_KEY_ID_FILE)
fi                                                             
                                                               
export MINIO_SECRET_ACCESS_KEY=$MINIO_SECRET_ACCESS_KEY        
if [[ -f ${MINIO_SECRET_ACCESS_KEY_FILE} ]] ; then             
    export MINIO_SECRET_ACCESS_KEY=$(cat $MINIO_SECRET_ACCESS_KEY_FILE)
fi                                                                     
                                                                       
export MINIO_DEFAULT_REGION=$MINIO_REGION                              
export MINIO_ALIAS=$MINIO_ALIAS                                        
export MINIO_HOSTNAME=$MINIO_HOSTNAME                                  
export MINIO_SUBDIRECTORY=$MINIO_SUBDIRECTORY                          
export MINIO_BUCKET=$MINIO_BUCKET                                      
export BACKUP_DIR=$BACKUP_DIR     
export POSTGRES_EXCLUDE_TABLE=${POSTGRES_EXCLUDE_TABLE}     
export POSTGRES_DUMP_FORMAT=${POSTGRES_DUMP_FORMAT}      
export POSTGRES_SPLIT_TABLE_AND_DATA=${POSTGRES_SPLIT_TABLE_AND_DATA}                         
                                                                       
if [ -z "${MINIO_ATTRIBUTES}" ]; then                                  
        attr=""                                                        
else                                                                   
    attr="--attr $MINIO_ATTRIBUTES"                                    
fi                                                                     
                                                                       
if [ -z "${MINIO_TAGS}" ]; then                                        
    tags=""                                                            
else                                                                   
    tags="--tags $MINIO_TAGS"                                          
fi                                                                     
                                                                       
if [ -z "${MINIO_SUBDIRECTORY}" ]; then
    DEST_DIR="$MINIO_ALIAS/$MINIO_BUCKET"                          
else                                                                   
    DEST_DIR="$MINIO_ALIAS/$MINIO_BUCKET/$MINIO_SUBDIRECTORY"          
fi                                                                     
DESTINATION="$DEST_DIR/$(date +"%Y-%m-%dT%H:%M:%SZ")_${POSTGRES_DATABASE}.sql.gz"
                                                                                 
export PGPASSWORD=$POSTGRES_PASSWD

if [ -z "${POSTGRES_EXCLUDE_TABLE}" ]; then
    EXCLUDE_TABLE=""                          
else                                                                   
    EXCLUDE_TABLE="--exclude-table-data=$POSTGRES_EXCLUDE_TABLE"          
fi  

if [ -z "${POSTGRES_DUMP_FORMAT}" ]; then                                  
    DUMP_FORMAT="--format=plain"                                                        
else                                                                   
    DUMP_FORMAT="--format=$POSTGRES_DUMP_FORMAT"                                    
fi 

POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS $DUMP_FORMAT $EXCLUDE_TABLE "
                                                                                               
echo "Creating dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..."

if [ -z "${POSTGRES_SPLIT_TABLE_AND_DATA}" ]  && [ "${POSTGRES_SPLIT_TABLE_AND_DATA}" == "true" ]; then 
    echo "Creating schema dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..."
    pg_dump --schema-only $POSTGRES_HOST_OPTS $POSTGRES_DATABASE | gzip > ${BACKUP_DIR}/dump.sql.gz

    echo "Creating datas dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..."
    pg_dump --data-only $POSTGRES_HOST_OPTS $POSTGRES_DATABASE | gzip > ${BACKUP_DIR}/dump.sql.gz                               
else                                                                   
    echo "Creating dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..."
    pg_dump $POSTGRES_HOST_OPTS $POSTGRES_DATABASE | gzip > ${BACKUP_DIR}/dump.sql.gz        
fi 
             
                                                                                               
echo "Uploading dump to $DESTINATION"                                                          
ARCH=$(uname -m)                                                                               
if [ "$ARCH" == "aarch64" ] ; then                                                             
    echo "Architecture aarch64"                                                                
    #bash +o history                                                                       
    ~/minio-binaries/mc_arm64 alias set $MINIO_ALIAS $MINIO_HOSTNAME $MINIO_ACCESS_KEY_ID $MINIO_SECRET_ACCESS_KEY
    #bash -o history                                                                                              
    ~/minio-binaries/mc_arm64 cp ${BACKUP_DIR}/dump.sql.gz $DESTINATION $attr $tags                                   
else                                                                                                                  
    echo "Architecture amd64"                                                                                         
    #bash +o history                                                                                              
    ~/minio-binaries/mc_amd64 alias set ${MINIO_ALIAS} ${MINIO_HOSTNAME} ${MINIO_ACCESS_KEY_ID} ${MINIO_SECRET_ACCESS_KEY}         
    #bash -o history                                                                                              
    ~/minio-binaries/mc_amd64 cp $BACKUP_DIR/dump.sql.gz $DESTINATION $attr $tags                                                  
fi                                                                                                                    
rm ${BACKUP_DIR}/dump.sql.gz
