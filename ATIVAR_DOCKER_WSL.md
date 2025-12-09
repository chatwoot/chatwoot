# 🔧 Ativar Integração Docker com WSL2

## Problema
O Docker não está disponível no WSL porque a integração não está ativada no Docker Desktop.

## ✅ Solução Passo a Passo

### 1. Abrir Docker Desktop
- Abra o **Docker Desktop** no Windows
- Aguarde até que o ícone da baleia fique verde (Docker está rodando)

### 2. Ativar Integração WSL
1. Clique no **ícone de engrenagem** (Settings) no canto superior direito
2. Vá em **Resources** → **WSL Integration**
3. **Ative o toggle** "Enable integration with my default WSL distro"
4. **Marque a checkbox** ao lado de **"Ubuntu"** (ou sua distro WSL)
5. Clique em **"Apply & Restart"**
6. Aguarde o Docker Desktop reiniciar

### 3. Verificar no WSL
Depois que o Docker Desktop reiniciar, volte ao terminal WSL e execute:

```bash
docker ps
```

Se funcionar, você verá uma lista (mesmo que vazia) de containers.

### 4. Se Ainda Não Funcionar

#### Opção A: Reiniciar WSL
No PowerShell do Windows (como Administrador), execute:
```powershell
wsl --shutdown
```
Depois, abra o terminal WSL novamente e teste:
```bash
docker ps
```

#### Opção B: Verificar se Docker Desktop está rodando
- Verifique se o ícone da baleia no system tray está verde
- Se estiver amarelo ou vermelho, aguarde ou reinicie o Docker Desktop

#### Opção C: Instalar Docker diretamente no WSL (Alternativa)
Se a integração não funcionar, você pode instalar Docker diretamente:

```bash
# Atualizar pacotes
sudo apt update

# Instalar Docker
sudo apt install docker.io -y

# Iniciar serviço Docker
sudo service docker start

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Fazer logout e login novamente no WSL, depois testar:
docker ps
```

## 🎯 Após Ativar a Integração

Quando o `docker ps` funcionar, execute:

```bash
cd /home/mathe/chatwoot-src

# Login no Docker Hub
docker login

# Build da imagem
docker build -t houi/chatkivo:v0.1 -f docker/Dockerfile .

# Push para Docker Hub
docker push houi/chatkivo:v0.1
```

## 📸 Onde Encontrar as Configurações

No Docker Desktop:
- **Settings** (ícone de engrenagem) → **Resources** → **WSL Integration**
- Certifique-se de que "Ubuntu" está marcado e habilitado

## ⚠️ Importante

- O Docker Desktop **deve estar rodando** para que o Docker funcione no WSL
- Após ativar a integração, pode ser necessário **reiniciar o terminal WSL**
- Se mudar de distro WSL, você precisa ativar a integração para cada distro separadamente
