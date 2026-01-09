#!/bin/sh

#  Database settings
POSTGRES_URL="db_postgres"
CONTAINER_DB="$(docker container ps -f=name=db_postgres -q)"
USERNAME="root"
PASSWORD="${DOCKER_SECRET_DB}"
PG_DB="postgres"

# Vault politicies
POLICIES="../policies"
ROLES="../roles"

# Github settings
GH_ORG="DevSecOpsOn"

(

  # Dynamic Secrets: Database Secrets Engine
  docker container exec -it $CONTAINER_DB psql -U $USERNAME $PG_DB -c "CREATE ROLE \"ro\" NOINHERIT;"
  docker container exec -it $CONTAINER_DB psql -U $USERNAME $PG_DB -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"ro\";"
  docker container exec -it $CONTAINER_DB psql -U $USERNAME $PG_DB -c "CREATE DATABASE junttus;"

  vault secrets enable database

  vault secrets list

  vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@$POSTGRES_URL/$PG_DB?sslmode=disable" \
  allowed_roles=* \
  username="$USERNAME" \
  password="$PASSWORD"

  vault write database/roles/readonly \
  db_name=postgresql \
  creation_statements=@$ROLES/readonly.sql \
  default_ttl=5m \
  max_ttl=7m

  vault read database/creds/readonly

  docker container exec -it $CONTAINER_DB psql -U $USERNAME $PG_DB -c "SELECT usename, valuntil FROM pg_user;"

  vault write sys/policies/password/db_password policy=@$POLICIES/db_password.hcl

  vault read sys/policies/password/db_password/generate

  vault write database/config/postgresql \
     password_policy="db_password"

  vault read database/creds/readonly

  vault write database/config/postgresql \
    username_template="devops-{{.RoleName}}-{{unix_time}}-{{random 8}}"

  vault read database/creds/readonly

)
