# 🚀 Comandos para Executar Agora

Como o ambiente não está mostrando a saída do Docker, execute estes comandos manualmente no seu terminal:

## 1. Verificar Docker

```bash
cd /home/mathe/chatwoot-src
docker info
```

Se o Docker não estiver rodando, inicie-o primeiro.

## 2. Login no Docker Hub (se necessário)

```bash
docker login
```

Digite seu usuário `houi` e senha quando solicitado.

## 3. Build da Imagem

```bash
docker build -t houi/chatkivo:v0.1 -f docker/Dockerfile .
```

**Isso pode levar 10-20 minutos.** O build irá:
- Baixar as imagens base (Ruby, Node.js)
- Instalar dependências (bundle install, pnpm install)
- Compilar assets de produção
- Criar a imagem final

## 4. Verificar se a Imagem foi Criada

```bash
docker images houi/chatkivo
```

Você deve ver algo como:
```
REPOSITORY        TAG    IMAGE ID       CREATED         SIZE
houi/chatkivo     v0.1   abc123def456   2 minutes ago   1.2GB
```

## 5. Push para Docker Hub

```bash
docker push houi/chatkivo:v0.1
```

**Nota:** O repositório `houi/chatkivo` será criado automaticamente no Docker Hub no primeiro push.

## 6. Verificar no Docker Hub

Após o push, verifique em: https://hub.docker.com/r/houi/chatkivo

## ⚠️ Se Encontrar Erros

### Erro: "unauthorized: authentication required"
```bash
docker login
```

### Erro: "denied: requested access to the resource is denied"
- Verifique se você está logado com o usuário correto (`houi`)
- Verifique se tem permissão para criar repositórios no Docker Hub

### Erro no Build
- Verifique se tem espaço em disco: `df -h`
- Verifique se o Dockerfile está correto: `cat docker/Dockerfile | head -20`
- Veja os logs completos do build

## ✅ Após o Push Bem-Sucedido

Quando o push for concluído, você pode fazer o deploy com:

```bash
docker-compose -f docker-compose.production.yaml up -d
```

---

**Dica:** Você também pode executar o script automatizado:

```bash
./build-and-push.sh
```

Este script faz tudo automaticamente e pergunta se você quer fazer o push após o build.
