# Deploy Chatwoot na VPS Hostinger

Este guia mostra como fazer o deploy do Chatwoot customizado na sua VPS da Hostinger.

## 📋 Pré-requisitos

- VPS Hostinger com Ubuntu 24.04 (já configurada)
- Acesso SSH ao servidor (`ssh root@72.60.49.217`)
- Domínio configurado (opcional, mas recomendado)

## 🔧 Passo 1: Conectar na VPS via SSH

No seu computador local (Windows), abra o PowerShell ou WSL e conecte:

```bash
ssh root@72.60.49.217
```

Digite a senha root quando solicitado.

## 🐳 Passo 2: Instalar Docker e Docker Compose na VPS

Após conectar na VPS, execute os seguintes comandos:

```bash
# Atualizar sistema
apt update && apt upgrade -y

# Instalar dependências
apt install -y apt-transport-https ca-certificates curl software-properties-common

# Adicionar repositório Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Instalar Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verificar instalação
docker --version
docker-compose --version

# Adicionar usuário root ao grupo docker (se necessário)
usermod -aG docker root
```

## 📦 Passo 3: Preparar Arquivos na VPS

Crie um diretório para o projeto:

```bash
mkdir -p /opt/chatwoot
cd /opt/chatwoot
```

## 📤 Passo 4: Transferir Arquivos do Seu Computador para a VPS

**Opção A: Usando SCP (do seu computador Windows/WSL)**

No seu computador local, navegue até a pasta do projeto e execute:

```bash
# Transferir docker-compose.production.yaml
scp docker-compose.production.yaml root@72.60.49.217:/opt/chatwoot/

# Transferir arquivo .env (você precisará criar/editá-lo primeiro)
scp .env root@72.60.49.217:/opt/chatwoot/
```

**Opção B: Criar arquivos diretamente na VPS**

Conecte na VPS e crie os arquivos:

```bash
cd /opt/chatwoot
nano docker-compose.production.yaml
```

Cole o conteúdo do `docker-compose.production.yaml` e salve (Ctrl+O, Enter, Ctrl+X).

## ⚙️ Passo 5: Configurar arquivo .env na VPS

Crie o arquivo `.env` na VPS:

```bash
cd /opt/chatwoot
nano .env
```

Configure as variáveis obrigatórias:

```bash
# URL do seu domínio (ou IP da VPS se não tiver domínio)
FRONTEND_URL=https://seu-dominio.com
# OU se não tiver domínio ainda:
# FRONTEND_URL=http://72.60.49.217:3000

# Senha do PostgreSQL (use uma senha forte e única)
POSTGRES_PASSWORD=sua_senha_forte_postgres_aqui

# Senha do Redis (use uma senha forte e única)
REDIS_PASSWORD=sua_senha_forte_redis_aqui

# SECRET_KEY_BASE (gere uma nova chave)
SECRET_KEY_BASE=$(openssl rand -hex 64)

# Outras variáveis importantes
RAILS_ENV=production
NODE_ENV=production
INSTALLATION_ENV=docker

# Force SSL (desative se não tiver SSL ainda)
FORCE_SSL=false
```

**Para gerar SECRET_KEY_BASE na VPS:**

```bash
openssl rand -hex 64
```

Copie o resultado e adicione no `.env`:

```bash
SECRET_KEY_BASE=resultado_do_comando_acima
```

Salve o arquivo (Ctrl+O, Enter, Ctrl+X).

## 🔐 Passo 6: Atualizar docker-compose.production.yaml

Edite o arquivo para garantir que a senha do PostgreSQL está sendo lida do .env:

```bash
cd /opt/chatwoot
nano docker-compose.production.yaml
```

Certifique-se de que a seção `postgres` está assim:

```yaml
postgres:
  image: pgvector/pgvector:pg16
  restart: always
  ports:
    - '127.0.0.1:5432:5432'
  volumes:
    - postgres_data:/var/lib/postgresql/data
  environment:
    - POSTGRES_DB=chatwoot
    - POSTGRES_USER=postgres
    - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
  env_file: .env
```

## 🚀 Passo 7: Fazer o Deploy

Na VPS, execute:

```bash
cd /opt/chatwoot

# Baixar a imagem do Docker Hub
docker pull houi/chatkivo:v0.1

# Iniciar os containers
docker-compose -f docker-compose.production.yaml up -d
```

## ✅ Passo 8: Verificar o Deploy

```bash
# Ver status dos containers
docker-compose -f docker-compose.production.yaml ps

# Ver logs (aguarde alguns minutos para inicialização)
docker-compose -f docker-compose.production.yaml logs -f

# Ver logs de um serviço específico
docker-compose -f docker-compose.production.yaml logs -f rails
```

**Aguarde 2-3 minutos** para o Rails inicializar completamente. Você verá mensagens como:

```
rails_1    | => Booting Puma
rails_1    | => Rails 7.x.x application starting in production
rails_1    | => Run `bin/rails server --help` for more startup options
rails_1    | Puma starting in single mode...
```

## 🌐 Passo 9: Configurar Nginx como Proxy Reverso (Recomendado)

Para expor a aplicação na porta 80/443, instale e configure o Nginx:

```bash
# Instalar Nginx
apt install -y nginx

# Criar configuração do Nginx
nano /etc/nginx/sites-available/chatwoot
```

Cole a seguinte configuração:

```nginx
server {
    listen 80;
    server_name seu-dominio.com;  # OU 72.60.49.217 se não tiver domínio

    client_max_body_size 20M;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Ative a configuração:

```bash
# Criar link simbólico
ln -s /etc/nginx/sites-available/chatwoot /etc/nginx/sites-enabled/

# Remover configuração padrão (opcional)
rm /etc/nginx/sites-enabled/default

# Testar configuração
nginx -t

# Reiniciar Nginx
systemctl restart nginx
systemctl enable nginx
```

## 🔥 Passo 10: Configurar Firewall (UFW)

```bash
# Instalar UFW
apt install -y ufw

# Permitir SSH
ufw allow 22/tcp

# Permitir HTTP e HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Ativar firewall
ufw enable

# Ver status
ufw status
```

## 📝 Passo 11: Configurar SSL com Let's Encrypt (Opcional mas Recomendado)

Se você tem um domínio configurado:

```bash
# Instalar Certbot
apt install -y certbot python3-certbot-nginx

# Obter certificado SSL
certbot --nginx -d seu-dominio.com

# Renovação automática (já configurado automaticamente)
certbot renew --dry-run
```

Após isso, atualize o `.env`:

```bash
nano /opt/chatwoot/.env
```

Altere:

```bash
FRONTEND_URL=https://seu-dominio.com
FORCE_SSL=true
```

Reinicie os containers:

```bash
cd /opt/chatwoot
docker-compose -f docker-compose.production.yaml restart rails
```

## 🔍 Comandos Úteis

```bash
# Ver status dos containers
docker-compose -f docker-compose.production.yaml ps

# Ver logs em tempo real
docker-compose -f docker-compose.production.yaml logs -f

# Parar os serviços
docker-compose -f docker-compose.production.yaml down

# Reiniciar os serviços
docker-compose -f docker-compose.production.yaml restart

# Atualizar a imagem e reiniciar
docker pull houi/chatkivo:v0.1
docker-compose -f docker-compose.production.yaml up -d --force-recreate

# Ver uso de recursos
docker stats

# Acessar shell do container Rails
docker-compose -f docker-compose.production.yaml exec rails bash

# Executar comandos Rails
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails console
```

## 🐛 Troubleshooting

### Containers não iniciam

```bash
# Ver logs detalhados
docker-compose -f docker-compose.production.yaml logs

# Verificar se as portas estão livres
netstat -tulpn | grep -E '3000|5432|6379'
```

### Erro de conexão com banco de dados

- Verifique se `POSTGRES_PASSWORD` no `.env` está correto
- Verifique se o container postgres está rodando: `docker ps`

### Erro "Image not found"

```bash
# Verificar se a imagem existe
docker images | grep chatkivo

# Se não existir, fazer pull novamente
docker pull houi/chatkivo:v0.1
```

### Aplicação não acessível externamente

- Verifique o firewall: `ufw status`
- Verifique se o Nginx está rodando: `systemctl status nginx`
- Verifique os logs do Nginx: `tail -f /var/log/nginx/error.log`

### Reiniciar tudo do zero

```bash
cd /opt/chatwoot
docker-compose -f docker-compose.production.yaml down -v
docker-compose -f docker-compose.production.yaml up -d
```

## 📚 Próximos Passos

1. **Configurar SMTP** para envio de emails (edite o `.env`)
2. **Configurar backup** do banco de dados PostgreSQL
3. **Monitoramento** - Configure logs e alertas
4. **Atualizações** - Mantenha Docker e imagens atualizadas

## 🔗 Recursos

- [Documentação Chatwoot](https://www.chatwoot.com/docs)
- [Docker Hub - houi/chatkivo](https://hub.docker.com/r/houi/chatkivo)
- [Documentação Nginx](https://nginx.org/en/docs/)
