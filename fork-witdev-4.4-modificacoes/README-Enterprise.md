# Chatwoot Enterprise Edition v4.3.0

## 🚀 Imagem Docker com Funcionalidades Enterprise Desbloqueadas

Esta é uma versão customizada do Chatwoot com todas as funcionalidades Enterprise habilitadas para fins educacionais.

### 📦 Informações da Imagem

- **Imagem**: `witrocha/chatwit:v4.3.0`
- **Imagem**: `witrocha/chatwit:latest`
- **Base**: Ruby 3.4.4 Alpine
- **Node**: v23.7.0
- **Funcionalidades**: Enterprise Edition

### ✨ Funcionalidades Enterprise Incluídas

- ✅ **Disable Branding** - Remove a marca Chatwoot
- ✅ **Audit Logs** - Logs detalhados de auditoria
- ✅ **SLA** - Service Level Agreements
- ✅ **Captain Integration** - Integração com IA
- ✅ **Custom Roles** - Funções personalizadas
- ✅ **Response Bot** - Bot de respostas automáticas

### 🔧 Configuração Automática

A imagem vem pré-configurada com:
- Plano Enterprise habilitado
- Limite de 100 agentes
- Funcionalidades Enterprise ativadas automaticamente

### 📋 Como Usar no Docker Swarm

1. **Baixe o arquivo de exemplo**: `chatwoot-enterprise.yaml`

2. **Configure suas variáveis de ambiente** no arquivo `.env`

3. **Deploy no Swarm**:
```bash
docker stack deploy -c chatwoot-enterprise.yaml chatwoot
```

### 🏗️ Como Foi Construída

#### Arquivos Principais:
- `Dockerfile.enterprise` - Dockerfile customizado
- `docker/entrypoints/rails-enterprise.sh` - Script de inicialização
- `setup_enterprise.rb` - Script de configuração Enterprise
- `docker-compose.build.yml` - Configuração de build

#### Processo de Build:
```bash
# Build local
docker compose -f docker-compose.build.yml build chatwoot-enterprise

# Tag e Push para Docker Hub
docker tag witrocha/chatwit:v4.3.0 witrocha/chatwit:latest
docker push witrocha/chatwit:v4.3.0
docker push witrocha/chatwit:latest
```

### 📝 Diferenças da Versão Original

1. **Entrypoint Customizado**: Configura automaticamente as funcionalidades Enterprise
2. **Variáveis Pré-configuradas**: `INSTALLATION_PRICING_PLAN=enterprise`
3. **Setup Automático**: Executa configuração Enterprise na primeira inicialização
4. **Funcionalidades Desbloqueadas**: Todas as features premium habilitadas

### ⚙️ Configuração do Banco

A imagem executa automaticamente:
- `bundle exec rails db:chatwoot_prepare` - Prepara o banco
- Configuração do plano Enterprise
- Habilitação das funcionalidades para todas as contas

### 🔒 Considerações de Licença

Esta imagem é destinada exclusivamente para:
- ✅ Fins educacionais
- ✅ Desenvolvimento e testes
- ✅ Ambientes de homologação

**⚠️ Para uso em produção, adquira uma licença Enterprise oficial do Chatwoot.**

### 🆘 Suporte e Problemas

Se encontrar problemas:

1. Verifique se o banco PostgreSQL está acessível
2. Confirme que as variáveis de ambiente estão corretas
3. Consulte os logs: `docker service logs <service_name>`

### 📊 Monitoramento

A imagem inclui logs detalhados do processo de configuração Enterprise:
- ✅ Configuração do plano
- ✅ Habilitação de funcionalidades
- ✅ Status de cada conta configurada

### 🔄 Atualização

Para atualizar:
```bash
docker service update --image witrocha/chatwit:latest <service_name>
```

---

**Criado para fins educacionais** 📚  
**Baseado no Chatwoot Open Source** 🌟 