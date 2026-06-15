#!/usr/bin/env bash
set -euo pipefail

cd /opt/deepulogger
mkdir -p /opt/deepulogger/data

if [ ! -f .env ]; then
  JWT_SECRET="$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")"
  {
    echo "PORT=8095"
    echo "DATABASE_PATH=/opt/deepulogger/data/deepulogger.sqlite"
    echo "JWT_SECRET=${JWT_SECRET}"
    echo "ADMIN_EMAIL=${ADMIN_EMAIL:?Set ADMIN_EMAIL before first deploy}"
    echo "ADMIN_PASSWORD=${ADMIN_PASSWORD:?Set ADMIN_PASSWORD before first deploy}"
  } > .env
fi

npm install --omit=dev
npm run migrate
npm run seed

if ! command -v pm2 >/dev/null 2>&1; then
  npm install -g pm2
fi

pm2 delete deepulogger-api >/dev/null 2>&1 || true
pm2 start src/index.js --name deepulogger-api --update-env
pm2 save
