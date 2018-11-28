FROM postgres:9.4

RUN mkdir -p /docker-entrypoint-initdb.d

COPY docker/db/init-robot-dbs.sh /docker-entrypoint-initdb.d/init-robot-dbs.sh

EXPOSE 5432
