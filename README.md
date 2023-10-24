# Postgres indexing
A few examples of postgres indexes with a presentation to understand how they work.

The docker-compose file has 2 services running:
- `postgres`: the database.
- `pgadmin`: the web interface to manage the database.

The postgres service is configured with the volume `schema` pointing to the local folder `schema` so we can share sql scripts and run them locally. It is also executing a command to install the `pg_stat_statements` extension.

The pgadmin service is configured with the volume `pgadmin` pointing to the local folder `pgadmin` so we can persist the login credentials and the server's configuration when stopping and starting the service. `DO NOT DO THIS with a production database`.

We also have a `Makefile` to simplify the execution of scripts.

## How to run
To build and run the containers:
> `make up`

To finish installing the `pg_stat_statements` extension, we need to run the following command (just once):
> `make install_pg_stats`

To create the schema, tables and seed data from the file `1.schema.sql`:
> `make create_schema`

To dump the database to a file:
> `make dump`

To restore the database from a file:
> `make restore`

To connect to the database using psql:
> `make psql`

Some useful commands in psql:
> `SET schema 'webstore';` \
  `\d` \
  `\d product` \
  `\dt *.*` \
  `\dnS`

## Using the pgadmin web interface
Go to `http://localhost:5050` and log in with the credentials `root@email.com` and `root`.
Then add a new server with any name and use the following connection details:
- Host: `postgres`
- Port: `5432`
- Username: `postgres`
- Password: `postgres`

Note: if you change the password in the docker-compose file, you need to change it here too.
