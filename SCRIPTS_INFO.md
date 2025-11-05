# 📋 Scripts do Chatwoot - Informações

## Scripts Mantidos

### 1. `setup.sh` ⭐ (PRINCIPAL)
**O que faz:** Script completo de setup que configura tudo automaticamente.

**Uso:**
```bash
./setup.sh
```

**Funcionalidades:**
- ✅ Verifica e instala dependências (Ruby, Node.js, PM2)
- ✅ Instala gems e pacotes npm se necessário
- ✅ Configura PostgreSQL (verifica senha, corrige host)
- ✅ Configura Redis (verifica instalação e status)
- ✅ Cria e migra banco de dados
- ✅ Verifica scripts PM2
- ✅ Fornece instruções finais

**Quando usar:** Execute uma vez após clonar o repositório ou quando precisar configurar do zero.

---

### 2. `bin/pm2-web.sh`
**O que faz:** Script executado pelo PM2 para iniciar o servidor web Rails.

**Uso:** Automático (chamado pelo PM2)

**Funcionalidades:**
- Executa `ip_lookup:setup`
- Inicia servidor Rails na porta 3000
- Escuta em `0.0.0.0` (aceita conexões externas)

**Não execute manualmente** - É usado pelo PM2 via `ecosystem.config.js`

---

### 3. `bin/pm2-worker.sh`
**O que faz:** Script executado pelo PM2 para iniciar o worker Sidekiq.

**Uso:** Automático (chamado pelo PM2)

**Funcionalidades:**
- Define `RAILS_ENV`
- Executa `ip_lookup:setup`
- Inicia Sidekiq worker

**Não execute manualmente** - É usado pelo PM2 via `ecosystem.config.js`

---

### 4. `ecosystem.config.js`
**O que faz:** Configuração do PM2 com os processos do Chatwoot.

**Uso:**
```bash
pm2 start ecosystem.config.js
pm2 restart ecosystem.config.js
pm2 stop ecosystem.config.js
```

**Processos configurados:**
- `chatwoot-web`: Servidor Rails
- `chatwoot-worker`: Worker Sidekiq

---

## Arquivos de Documentação

### `README_PM2.md`
Guia completo com todas as instruções de uso do PM2, troubleshooting e comandos úteis.

---

## Scripts Removidos (consolidados)

Os seguintes scripts foram removidos e suas funcionalidades foram integradas no `setup.sh`:

- ❌ `setup-db.sh` → Integrado em `setup.sh`
- ❌ `fix-postgres-password.sh` → Integrado em `setup.sh`
- ❌ `FIX_POSTGRES.md` → Informações em `README_PM2.md`
- ❌ `SETUP_INSTRUCTIONS.md` → Informações em `README_PM2.md`
- ❌ `PM2_GUIDE.md` → Informações em `README_PM2.md`
- ❌ `STATUS.md` → Informações em `README_PM2.md`

---

## Fluxo de Uso Recomendado

1. **Primeira vez:**
   ```bash
   ./setup.sh
   pm2 start ecosystem.config.js
   ```

2. **Uso diário:**
   ```bash
   pm2 status        # Ver status
   pm2 logs          # Ver logs
   pm2 restart all   # Reiniciar se necessário
   ```

3. **Troubleshooting:**
   ```bash
   pm2 logs          # Ver erros
   ./setup.sh        # Reconfigurar se necessário
   ```

---

## Estrutura Final

```
chatwoot/
├── setup.sh              ⭐ Script principal de setup
├── ecosystem.config.js    Configuração PM2
├── bin/
│   ├── pm2-web.sh        Script servidor web (PM2)
│   └── pm2-worker.sh     Script worker (PM2)
├── README_PM2.md         📖 Documentação completa
└── SCRIPTS_INFO.md       📋 Este arquivo
```

---

**Total:** 1 script principal + 2 scripts PM2 + 2 arquivos de configuração + 2 documentos

