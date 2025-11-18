#!/bin/sh

set -ex

# -------------------------------
# 0. Limpeza inicial
# -------------------------------
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

echo "⏳ Aguardando Postgres..."

# -------------------------------
# 1. Esperar o Postgres
# -------------------------------

# Se DATABASE_URL existir, o Chatwoot substitui automaticamente…
$(docker/entrypoints/helpers/pg_database_url.rb)

PG_READY="pg_isready -h $POSTGRES_HOST -p ${POSTGRES_PORT:-5432} -U $POSTGRES_USERNAME"

until $PG_READY; do
  echo "Postgres indisponível… tentando novamente..."
  sleep 2
done

echo "✅ Postgres conectado!"

# -------------------------------
# 2. Instalar gems se faltar algo
# -------------------------------

echo "📦 Verificando dependências Ruby..."
bundle check || bundle install

# -------------------------------
# 3. Criar banco se não existir
# -------------------------------

echo "🛢  Verificando existência do banco: $POSTGRES_DATABASE"

bundle exec rails db:exists 2>/dev/null

if [ $? -ne 0 ]; then
  echo "📌 Banco não existe — criando..."
  bundle exec rails db:create
else
  echo "✔ Banco já existe."
fi

# -------------------------------
# 4. Rodar migrations
# -------------------------------

echo "🧩 Rodando migrations..."
bundle exec rails db:migrate

# -------------------------------
# 5. Precompile de assets (somente web)
# -------------------------------

if echo "$@" | grep -q "rails s"; then
  echo "🎨 Precompilando assets..."
  bundle exec rails assets:precompile
fi

# -------------------------------
# 6. Iniciar processo final
# -------------------------------

echo "🚀 Iniciando serviço: $@"
exec "$@"
