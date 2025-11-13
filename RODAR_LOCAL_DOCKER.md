# 🚀 Como Rodar Chatwoot Local com Docker

## Pré-requisitos
- Docker Desktop rodando
- Git Bash (Windows)

## Passos

### 1. Aplicar configurações Docker (primeira vez ou após stash)
```bash
git stash apply stash@{0}
```

### 2. Corrigir line endings (necessário no Windows)
```bash
dos2unix docker/entrypoints/rails.sh docker/entrypoints/vite.sh
```

### 3. Buildar as imagens (primeira vez ou após mudanças no código)
```bash
docker compose build
```
⏱️ *Demora ~10-15 minutos na primeira vez*

### 4. Subir os containers
```bash
docker compose up -d
```

### 5. Preparar o banco (primeira vez)
```bash
docker compose exec -T rails bundle exec rails db:chatwoot_prepare
```

### 6. Aplicar migrations (após criar novas migrations)
```bash
docker compose exec -T rails bundle exec rails db:migrate
```

### 7. Reiniciar Rails (após migrations)
```bash
docker compose restart rails
```

## Acessar

- **Aplicação**: http://localhost:3000
- **Email**: `admin@heycommerce.com`
- **Senha**: `Admin@123456`

## Criar Admin (se necessário)

Rode o script:
```bash
docker compose exec -T rails bundle exec rails runner create_admin_temp.rb
```

## Comandos Úteis

```bash
# Ver logs
docker compose logs rails --tail=50 -f

# Parar tudo
docker compose down

# Rebuild após mudanças
docker compose build && docker compose up -d

# Ver status
docker compose ps
```

## Após testar: Guardar alterações Docker

```bash
git stash push -m "config docker windows local" docker-compose.yaml docker/entrypoints/rails.sh docker/entrypoints/vite.sh
```
