# 🔧 Solução para Erro 500 do Docker

## Problema
```
ERROR: request returned 500 Internal Server Error for API route and version
```

Este erro indica que o Docker Desktop está com problemas ou travado.

## ✅ Soluções (Tente nesta ordem)

### Solução 1: Reiniciar Docker Desktop (Mais Comum)

1. **Feche completamente o Docker Desktop**
   - Clique com botão direito no ícone da baleia na system tray
   - Clique em "Quit Docker Desktop"
   - Aguarde alguns segundos

2. **Abra o Docker Desktop novamente**
   - Procure "Docker Desktop" no menu Iniciar
   - Aguarde até o ícone ficar verde (pode levar 1-2 minutos)

3. **Teste novamente**
   ```bash
   docker ps
   ```

4. **Se funcionar, execute o build:**
   ```bash
   docker build -t houi/chatkivo:v0.1 -f docker/Dockerfile .
   ```

### Solução 2: Reiniciar WSL

Se a Solução 1 não funcionar:

1. **No PowerShell (como Administrador):**
   ```powershell
   wsl --shutdown
   ```

2. **Aguarde 10 segundos**

3. **Abra o terminal WSL novamente**

4. **Teste:**
   ```bash
   docker ps
   ```

5. **Se funcionar, execute o build**

### Solução 3: Reiniciar Docker Desktop + WSL

1. **Feche Docker Desktop** (botão direito no ícone → Quit)

2. **No PowerShell (como Administrador):**
   ```powershell
   wsl --shutdown
   ```

3. **Aguarde 30 segundos**

4. **Abra Docker Desktop novamente**
   - Aguarde até ficar verde

5. **Abra terminal WSL**

6. **Teste:**
   ```bash
   docker ps
   docker build -t houi/chatkivo:v0.1 -f docker/Dockerfile .
   ```

### Solução 4: Verificar Recursos do Docker Desktop

Se ainda não funcionar:

1. **Docker Desktop → Settings → Resources**
2. **Verifique se há recursos suficientes:**
   - CPU: pelo menos 2 cores
   - Memória: pelo menos 4GB (recomendado 8GB)
   - Disco: espaço suficiente

3. **Se necessário, ajuste e clique em "Apply & Restart"**

### Solução 5: Reinstalar Docker Desktop (Último Recurso)

Se nada funcionar:

1. **Desinstale Docker Desktop**
2. **Baixe a versão mais recente:** https://www.docker.com/products/docker-desktop
3. **Instale novamente**
4. **Configure a integração WSL** (Settings → Resources → WSL Integration)
5. **Teste novamente**

## 🎯 Comando de Teste

Após qualquer solução, teste com:

```bash
# Teste básico
docker ps

# Se funcionar, teste o build
docker build -t houi/chatkivo:v0.1 -f docker/Dockerfile .
```

## ⚠️ Dicas Importantes

1. **Sempre aguarde o Docker Desktop ficar verde** antes de executar comandos
2. **Não execute comandos Docker enquanto o Docker Desktop está iniciando**
3. **Se o erro persistir, reinicie o computador** (às vezes ajuda)

## 📊 Status do Docker Desktop

Verifique o ícone na system tray:
- 🟢 **Verde** = Funcionando (pode usar)
- 🟡 **Amarelo** = Iniciando (aguarde)
- 🔴 **Vermelho** = Erro (reinicie)

## 🔍 Verificação Rápida

Execute no PowerShell ou WSL:
```bash
docker info
```

Se mostrar informações do Docker, está funcionando. Se der erro, siga as soluções acima.
