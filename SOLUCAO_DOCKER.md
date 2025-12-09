# 🔧 Solução para Erro do Docker

## Problema Identificado

O erro `error during connect: Head "http://%2F%2F.%2Fpipe%2FdockerDesktopLinuxEngine/_ping"` indica que:

1. **Docker Desktop não está rodando** no Windows, OU
2. **Docker não está integrado com WSL2** corretamente

## ✅ Soluções

### Opção 1: Iniciar Docker Desktop (Recomendado)

1. **Abra o Docker Desktop no Windows**
   - Procure por "Docker Desktop" no menu Iniciar
   - Aguarde até que o ícone da baleia fique verde/estável

2. **Verifique a integração com WSL2**
   - Abra Docker Desktop → Settings → Resources → WSL Integration
   - Certifique-se de que "Ubuntu" está marcado
   - Clique em "Apply & Restart"

3. **Teste no WSL**
   ```bash
   # Dentro do WSL (não PowerShell)
   docker ps
   ```

### Opção 2: Executar dentro do WSL (Melhor)

**NÃO execute no PowerShell!** Execute dentro do terminal WSL:

1. **Abra o terminal WSL** (Ubuntu)
   - Pode ser através do VS Code: Terminal → New Terminal → Select WSL
   - Ou abra "Ubuntu" diretamente do menu Iniciar

2. **Navegue até o diretório**
   ```bash
   cd /home/mathe/chatwoot-src
   ```

3. **Verifique o Docker**
   ```bash
   docker ps
   ```

4. **Execute o build**
   ```bash
   docker build -t houi/chatkivo:v0.1 -f docker/Dockerfile .
   ```

### Opção 3: Usar Docker direto no WSL (Alternativa)

Se o Docker Desktop não funcionar, você pode instalar Docker diretamente no WSL:

```bash
# Dentro do WSL
sudo apt update
sudo apt install docker.io -y
sudo service docker start
sudo usermod -aG docker $USER

# Faça logout e login novamente, depois teste:
docker ps
```

## 🎯 Comandos Corretos

**Execute estes comandos DENTRO do WSL (não PowerShell):**

```bash
# 1. Verificar Docker
docker ps

# 2. Login (se necessário)
docker login

# 3. Build
cd /home/mathe/chatwoot-src
docker build -t houi/chatkivo:v0.1 -f docker/Dockerfile .

# 4. Push
docker push houi/chatkivo:v0.1
```

## ⚠️ Importante

- **NÃO execute comandos Docker no PowerShell** quando estiver trabalhando com WSL
- **Sempre execute dentro do terminal WSL/Ubuntu**
- Certifique-se de que o Docker Desktop está rodando antes de executar comandos

## 🔍 Verificação Rápida

Execute no WSL:
```bash
docker info
```

Se funcionar, você verá informações do Docker. Se não funcionar, siga as soluções acima.
