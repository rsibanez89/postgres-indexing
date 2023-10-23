up:
	docker-compose down
	docker-compose up --build

install_pg_stats:
	docker exec -it postgres su - postgres -c "psql -c 'CREATE EXTENSION IF NOT EXISTS pg_stat_statements;'"
	docker exec -it postgres su - postgres -c "psql -c 'SELECT * FROM pg_available_extensions WHERE installed_version IS NOT NULL;'"

exec:
	docker exec -it postgres sh

psql:
	docker exec -it postgres su - postgres -c "psql"

create_schema:
	docker exec -it postgres su - postgres -c "psql -f ../../../schema/1.schema.sql"

dump:
	docker exec -it postgres su - postgres -c "pg_dump > ../../../schema/db.sql"

restore:
	docker exec -it postgres su - postgres -c "psql < ../../../schema/db.sql"