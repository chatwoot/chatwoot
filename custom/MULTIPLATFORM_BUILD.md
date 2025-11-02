# CommMate Multi-Platform Build Setup

## ✅ **Configuração Completa!**

A imagem CommMate agora é buildada para **múltiplas arquiteturas**:

- **AMD64** (x86_64) - Servidores de produção
- **ARM64** (Apple Silicon) - Desenvolvimento local (Mac M1/M2)

---

## 🚀 **Como Usar**

### Build Multi-Plataforma

```bash
cd /Users/schimuneck/projects/commmmate/chatwoot
./custom/script/build_multiplatform.sh v4.7.0
```

### Push para Docker Hub

```bash
# Push com a tag de versão
podman manifest push commmate/commmate:v4.7.0 \
  docker://commmate/commmate:v4.7.0

# Tag e push como latest
podman tag commmate/commmate:v4.7.0 commmate/commmate:latest
podman manifest push commmate/commmate:latest \
  docker://commmate/commmate:latest
```

---

## 📋 **O Que o Script Faz**

1. **Cria um Manifest** - Container "virtual" que aponta para múltiplas imagens
2. **Build AMD64** - Para servidores de produção (~15-20 min)
3. **Build ARM64** - Para desenvolvimento local (~15-20 min)
4. **Inspecciona** - Mostra detalhes do manifest multi-plataforma

---

## 🔍 **Verificar Imagem Multi-Plataforma**

### Inspecionar Manifest Local

```bash
podman manifest inspect commmate/commmate:v4.7.0
```

### Inspecionar Manifest no Docker Hub

```bash
docker manifest inspect commmate/commmate:v4.7.0
```

Você verá algo como:

```json
{
  "manifests": [
    {
      "platform": {
        "architecture": "amd64",
        "os": "linux"
      }
    },
    {
      "platform": {
        "architecture": "arm64",
        "os": "linux"  
      }
    }
  ]
}
```

---

## ⏱️ **Tempo de Build**

- **AMD64**: ~15-20 minutos
- **ARM64**: ~15-20 minutos  
- **Total**: ~30-40 minutos

---

## 🐳 **Deploy em Produção**

Quando usar `commmate/commmate:v4.7.0` no docker-compose:

- **Docker automaticamente** puxa a imagem correta para a arquitetura
- **Servidor AMD64** → pega versão AMD64
- **Mac ARM64** → pega versão ARM64

---

## 📊 **Status do Build Atual**

**Build em Progresso**: `/tmp/commmate-build.log`

```bash
# Monitorar progresso
tail -f /tmp/commmate-build.log

# Ver últimas 50 linhas
tail -50 /tmp/commmate-build.log

# Verificar se ainda está rodando
ps aux | grep build_multiplatform
```

---

## 🔧 **Troubleshooting**

### Erro: "image name already in use"

```bash
# Limpar imagens antigas
podman rmi -f commmate/commmate:v4.7.0
podman manifest rm commmate/commmate:v4.7.0
```

### Build Falhou

```bash
# Ver logs completos
cat /tmp/commmate-build.log

# Tentar rebuild de uma plataforma específica
podman build --platform linux/amd64 \
  -f docker/Dockerfile.commmate \
  -t commmate/commmate:v4.7.0-amd64 \
  --build-arg RAILS_ENV=production \
  .
```

---

## 📚 **Arquivos Criados**

- `custom/script/build_multiplatform.sh` - Script principal
- `custom/MULTIPLATFORM_BUILD.md` - Esta documentação
- `/tmp/commmate-build.log` - Logs do build atual

---

## ✅ **Próximos Passos**

1. **Aguardar build** (~30-40 min)
2. **Push para Docker Hub**
3. **Deploy em produção**
4. **Verificar funcionamento**

---

**Build iniciado em**: 2025-11-02 16:34:17 UTC
**Versão**: v4.7.0
**Commit**: e30df982a
**Branch**: commmate/v4.7.0

