# Instruções de Deploy - Chatwoot Customizado

## ✅ O que foi feito

1. ✅ **Removidos todos os debugs** - Todos os `console.log` foram removidos dos arquivos Kanban
2. ✅ **Arquivo .env criado** - Template completo com todas as variáveis necessárias
3. ✅ **SECRET_KEY_BASE gerado** - Chave secreta gerada automaticamente
4. ✅ **docker-compose.production.yaml atualizado** - Configurado para usar `houi/chatkivo:v0.1`

## 📋 Próximos Passos

### 1. Configurar o arquivo `.env`

Edite o arquivo `.env` e preencha as seguintes variáveis obrigatórias:

```bash
# URL do seu domínio de produção
FRONTEND_URL=https://seu-dominio.com

# Senha do PostgreSQL (use uma senha forte)
POSTGRES_PASSWORD=sua_senha_forte_aqui

# Senha do Redis (use uma senha forte)
REDIS_PASSWORD=sua_senha_forte_aqui
```

### 2. Build e Push da Imagem Docker

Execute o script de deploy:

```bash
./deploy.sh
```

Ou execute manualmente:

```bash
# 1. Login no Docker Hub
docker login

# 2. Build da imagem
docker build -t houi/chatkivo:v0.1 -f docker/Dockerfile .

# 3. Push para Docker Hub
docker push houi/chatkivo:v0.1
```

**Nota:** O repositório `houi/chatkivo` será criado automaticamente no Docker Hub no primeiro push.

### 3. Deploy em Produção

Após o push ser concluído, você pode fazer o deploy usando:

```bash
docker-compose -f docker-compose.production.yaml up -d
```

Isso irá:
- Baixar a imagem `houi/chatkivo:v0.1` do Docker Hub
- Criar os containers (rails, sidekiq, postgres, redis)
- Iniciar todos os serviços

### 4. Verificar o Deploy

```bash
# Ver status dos containers
docker-compose -f docker-compose.production.yaml ps

# Ver logs
docker-compose -f docker-compose.production.yaml logs -f

# Parar os serviços
docker-compose -f docker-compose.production.yaml down
```

## 🔧 Configurações Adicionais (Opcional)

### SMTP (Envio de Emails)

Quando tiver um servidor SMTP, descomente e configure no `.env`:

```bash
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=seu_email@gmail.com
SMTP_PASSWORD=sua_senha_app
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true
```

### Storage em Cloud (Opcional)

Se quiser usar AWS S3 ou S3 Compatible, configure no `.env`:

```bash
ACTIVE_STORAGE_SERVICE=amazon  # ou s3_compatible

# Para AWS S3
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1
S3_BUCKET_NAME=seu-bucket
```

## 📝 Arquivos Modificados

- `app/javascript/dashboard/components-next/Contacts/Kanban/ContactsSidebar.vue` - Debugs removidos
- `app/javascript/dashboard/components-next/Contacts/Kanban/KanbanView.vue` - Debugs removidos
- `app/javascript/dashboard/components-next/Contacts/Kanban/KanbanColumn.vue` - Debugs removidos
- `.env` - Criado com template completo
- `docker-compose.production.yaml` - Atualizado para usar `houi/chatkivo:v0.1`

## 🐛 Troubleshooting

### Erro ao fazer push
- Verifique se está logado: `docker login`
- Verifique se tem permissão no repositório `houi/chatkivo`

### Erro ao iniciar containers
- Verifique se todas as variáveis no `.env` estão preenchidas
- Verifique os logs: `docker-compose -f docker-compose.production.yaml logs`

### Imagem não encontrada
- Certifique-se de que o push foi concluído: `docker images houi/chatkivo`
- Verifique no Docker Hub: https://hub.docker.com/r/houi/chatkivo

## 📚 Recursos

- [Documentação Chatwoot](https://www.chatwoot.com/docs)
- [Docker Hub - houi/chatkivo](https://hub.docker.com/r/houi/chatkivo)
