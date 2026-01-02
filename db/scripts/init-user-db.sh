#!/usr/bin/env bash
set -e

echo "Creating PostgreSQL databases and users..."

# Create the postgres role if it doesn't exist (common requirement for many applications)
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	DO \$\$
	BEGIN
		IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'postgres') THEN
			CREATE ROLE postgres WITH SUPERUSER CREATEDB CREATEROLE LOGIN;
		END IF;
	END
	\$\$;
EOSQL

# homarr database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER homarr WITH PASSWORD 'homarr_password';
	CREATE DATABASE homarr OWNER homarr;
	GRANT ALL PRIVILEGES ON DATABASE homarr TO homarr;
EOSQL

# hedgedoc database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER hedgedoc WITH PASSWORD 'hedgedoc_password';
	CREATE DATABASE hedgedoc OWNER hedgedoc;
	GRANT ALL PRIVILEGES ON DATABASE hedgedoc TO hedgedoc;
EOSQL

# coolify database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER coolify WITH PASSWORD 'coolify_password';
	CREATE DATABASE coolify OWNER coolify;
	GRANT ALL PRIVILEGES ON DATABASE coolify TO coolify;
EOSQL

# n8n database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER n8n WITH PASSWORD 'n8n_password';
	CREATE DATABASE n8n OWNER n8n;
	GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
EOSQL

# Activepieces database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER activepieces WITH PASSWORD 'activepieces_password';
	CREATE DATABASE activepieces OWNER activepieces;
	GRANT ALL PRIVILEGES ON DATABASE activepieces TO activepieces;
EOSQL

# Dokploy database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER dokploy WITH PASSWORD 'dokploy_password';
	CREATE DATABASE dokploy OWNER dokploy;
	GRANT ALL PRIVILEGES ON DATABASE dokploy TO dokploy;
EOSQL

# Dokku database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER dokku WITH PASSWORD 'dokku_password';
	CREATE DATABASE dokku OWNER dokku;
	GRANT ALL PRIVILEGES ON DATABASE dokku TO dokku;
EOSQL

# Komiser database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER komiser WITH PASSWORD 'komiser_password';
	CREATE DATABASE komiser OWNER komiser;
	GRANT ALL PRIVILEGES ON DATABASE komiser TO komiser;
EOSQL

# Grafana database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER grafana WITH PASSWORD 'grafana_password';
	CREATE DATABASE grafana OWNER grafana;
	GRANT ALL PRIVILEGES ON DATABASE grafana TO grafana;
EOSQL

# Passbolt database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER passbolt WITH PASSWORD 'passbolt_password';
	CREATE DATABASE passbolt OWNER passbolt;
	GRANT ALL PRIVILEGES ON DATABASE passbolt TO passbolt;
EOSQL

# TeamCity database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER teamcity WITH PASSWORD 'teamcity_password';
	CREATE DATABASE teamcitydb OWNER teamcity;
	GRANT ALL PRIVILEGES ON DATABASE teamcitydb TO teamcity;
EOSQL

# Create teamcity schema in teamcitydb database
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "teamcitydb" <<-EOSQL
	CREATE SCHEMA IF NOT EXISTS teamcity AUTHORIZATION teamcity;
EOSQL

# GoCD database and users
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE ROLE "gocd_database_user" PASSWORD 'gocd_database_password' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;
  CREATE DATABASE "gocd" ENCODING="UTF8" TEMPLATE="template0";
  GRANT ALL PRIVILEGES ON DATABASE "gocd" TO "gocd_database_user";
  ALTER ROLE "gocd_database_user" SUPERUSER;
EOSQL

# Gogs database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER gogs WITH PASSWORD 'gogs_password';
	CREATE DATABASE gogs OWNER gogs;
	GRANT ALL PRIVILEGES ON DATABASE gogs TO gogs;
EOSQL

# Concourse CI database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER concourseci WITH PASSWORD 'concourseci_password';
	CREATE DATABASE concourseci OWNER concourseci;
	GRANT ALL PRIVILEGES ON DATABASE concourseci TO concourseci;
EOSQL

# Drone Bitbucket database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER drone_bb WITH PASSWORD 'drone_bb_password';
	CREATE DATABASE drone_bitbucket OWNER drone_bb;
	GRANT ALL PRIVILEGES ON DATABASE drone_bitbucket TO drone_bb;
EOSQL

# Drone GitHub database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER drone_gh WITH PASSWORD 'drone_gh_password';
	CREATE DATABASE drone_github OWNER drone_gh;
	GRANT ALL PRIVILEGES ON DATABASE drone_github TO drone_gh;
EOSQL

# Harness database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER harness WITH PASSWORD 'harness_password';
	CREATE DATABASE harness OWNER harness;
	GRANT ALL PRIVILEGES ON DATABASE harness TO harness;
EOSQL

# Gitea database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER gitea WITH PASSWORD 'gitea_password';
	CREATE DATABASE gitea OWNER gitea;
	GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;
EOSQL

# Atuin database and user
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER atuin WITH PASSWORD 'atuin_password';
	CREATE DATABASE atuin OWNER atuin;
	GRANT ALL PRIVILEGES ON DATABASE atuin TO atuin;
EOSQL

echo "Database initialization completed successfully!"

echo "Bye ..."
