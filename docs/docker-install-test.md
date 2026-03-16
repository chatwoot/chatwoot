# Docker Compose para instalar e testar

Use o compose `docker-compose.install-test.yaml` para subir os serviços de desenvolvimento com PostgreSQL, Redis, Sidekiq, Vite, Mailhog e o scaffold `synapsea-analytics`.

## 1) Preparar ambiente

1. Copie o arquivo de ambiente:

```bash
cp .env.example .env
```

2. Ajuste variáveis obrigatórias no `.env` (principalmente `REDIS_PASSWORD`).

## 2) Instalar dependências e preparar banco

```bash
docker compose -f docker-compose.install-test.yaml run --rm setup
```

Esse passo executa:

- `bundle install`
- `pnpm install`
- `bundle exec rails db:prepare`
- `bundle exec rails db:seed`

## 3) Subir aplicação para testes manuais

```bash
docker compose -f docker-compose.install-test.yaml up -d
```

Serviços principais:

- Connect: `http://localhost:3000`
- Vite: `http://localhost:3036`
- Mailhog: `http://localhost:8025`
- Synapsea Analytics (scaffold): `http://localhost:4010`

## 4) Derrubar serviços

```bash
docker compose -f docker-compose.install-test.yaml down
```
