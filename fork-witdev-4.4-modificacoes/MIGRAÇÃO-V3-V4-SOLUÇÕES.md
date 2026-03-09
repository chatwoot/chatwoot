# 🚀 Chatwit v4 - Soluções para Migração v3→v4

## 📊 **Cenários Suportados**

### ✅ **Cenário 1: Instalação Limpa v4**
- Banco novo/vazio
- Todas as migrações executam em ordem
- ✅ **FUNCIONA PERFEITAMENTE**

### ✅ **Cenário 2: Migração v3→v4** 
- Banco existente do Chatwoot v3
- Precisa adicionar colunas `settings` e `csat_config`
- ✅ **FUNCIONA COM AS CORREÇÕES APLICADAS**

---

## 🔧 **Correções Implementadas**

### **1. Migração Robusta `CreateCaptainTables`**
```ruby
# db/migrate/20250104200055_create_captain_tables.rb
def create_assistants
  return if table_exists?(:captain_assistants)  # ← CORREÇÃO
  create_table :captain_assistants do |t|
    # ... código da tabela
  end
end
```

### **2. Verificação de Coluna `settings`**
```ruby
# db/migrate/20250416182131_flip_chatwoot_v4_default_feature_flag_installation_config.rb
if ActiveRecord::Base.connection.column_exists?(:accounts, :settings)  # ← CORREÇÃO
  Account.find_in_batches(batch_size: 100) do |accounts|
    accounts.each { |account| account.enable_features!('chatwoot_v4') }
  end
else
  Rails.logger.info "Skipping account feature enable - v3->v4 migration in progress"
end
```

### **3. Tarefas Inteligentes de Migração**
```ruby
# lib/tasks/chatwit_migrate.rake
task chatwit_smart_prepare: :environment do
  # Detecta automaticamente se é v3 ou v4
  # Aplica correções específicas para cada cenário
  # Ativa features após migração bem-sucedida
end
```

### **4. Entrypoint Enterprise Corrigido**
```bash
# docker/entrypoints/rails-enterprise.sh
if ActiveRecord::Base.connection.column_exists?(:accounts, :settings)
  # Ativar features Enterprise
else
  # Aguardar migração completar
end
```

---

## 🛠️ **Scripts de Correção**

### **Para Casos Emergenciais:**

```bash
# 1. Correção de tabelas Captain duplicadas
docker cp fix-captain-migration.rb [container]:/app/
docker exec [container] ruby fix-captain-migration.rb

# 2. Correção completa v3->v4
docker cp fix-v3-to-v4-migration.rb [container]:/app/
docker exec [container] ruby fix-v3-to-v4-migration.rb
```

---

## 📈 **Fluxo de Execução Corrigido**

### **Instalação Limpa v4:**
1. ✅ `bundle exec rails db:chatwoot_prepare`
2. ✅ Todas migrações executam normalmente 
3. ✅ Features Enterprise são ativadas
4. ✅ Aplicação inicia perfeitamente

### **Migração v3→v4:**
1. 🔍 Sistema detecta banco v3 (colunas ausentes)
2. ➕ Adiciona colunas `settings` e `csat_config`
3. 🔄 Executa migrações (com verificações robustas)
4. ✅ Ativa features v4 e Enterprise após migração
5. ✅ Aplicação funciona normalmente

---

## 🎯 **Resultados Esperados**

### **Logs de Sucesso:**
```
✅ Database ready to accept connections
✅ Bundle check passed
✅ [CHATWIT] Base já está no v4 - executando apenas setup normal
✅ Migração concluída!
✅ Features v4 ativadas com sucesso!
✅ Enterprise setup completed!
🎉 [CHATWIT] Aplicação pronta para iniciar!
=> Listening on http://0.0.0.0:3000
```

### **Problemas Resolvidos:**
- ❌ `PG::DuplicateTable: relation "captain_assistants" already exists`
- ❌ `undefined method 'settings' for an instance of Account`
- ❌ `Redis::CannotConnectError: unix://redisredis6379`
- ❌ `LoadError: cannot load such file -- annotate`

---

## 🚀 **Para Usar em Produção**

### **Opção 1: Redeploy Completo (Recomendado)**
```bash
# Todas as correções já estão no código
# Apenas faça redeploy da stack
docker stack deploy -c chatwitOFICIAL-PRODUCAO-SEM-TELEMETRIA-final.yaml chatwit
```

### **Opção 2: Correção em Container Ativo**
```bash
# Copiar scripts de correção
docker cp fix-v3-to-v4-migration.rb [container]:/app/

# Executar correção
docker exec [container] ruby fix-v3-to-v4-migration.rb

# Reiniciar aplicação
docker service update --force chatwit_chatwoot_app
```

---

## ✅ **Status Final**

- 🎉 **Instalação limpa v4**: ✅ FUNCIONANDO
- 🎉 **Migração v3→v4**: ✅ FUNCIONANDO  
- 🎉 **Features Enterprise**: ✅ FUNCIONANDO
- 🎉 **Redis/PostgreSQL**: ✅ FUNCIONANDO
- 🎉 **Bad Gateway**: ✅ RESOLVIDO

**O Chatwit v4 agora funciona perfeitamente em ambos os cenários!** 🚀 