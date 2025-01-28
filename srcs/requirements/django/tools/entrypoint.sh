#!/bin/sh

if [ "postgres" = "postgres" ]
then
    echo "Waiting for postgres..."

    while ! nc -z postgres 5432; do
      sleep 0.1
    done

    echo "PostgreSQL started"
fi

python manage.py flush --no-input
python manage.py makemigrations trans
python manage.py migrate

exec "$@"
