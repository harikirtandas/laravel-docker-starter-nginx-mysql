#!/bin/sh
# Escribe DB_CONNECTION=mysql y DB_DATABASE=<nombre real> en .env, una sola vez.
# Estas dos variables viven solo en .env (nunca como `environment:` del
# contenedor `app`, a diferencia de DB_HOST/DB_USERNAME/DB_PASSWORD) para que
# el phpunit.xml default de Laravel pueda aislar los tests en sqlite sin
# configuracion extra. Mismo patron que usa Laravel Sail.
set -eu
DB_NAME="$1"

if grep -q '^DB_CONNECTION=' .env; then
    sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env
else
    echo "DB_CONNECTION=mysql" >> .env
fi

if grep -q '^DB_DATABASE=' .env; then
    sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" .env
else
    echo "DB_DATABASE=${DB_NAME}" >> .env
fi

echo ".env: DB_CONNECTION=mysql, DB_DATABASE=${DB_NAME}"
