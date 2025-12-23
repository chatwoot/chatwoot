# Diagnóstico do Problema de Login

## Problema
Após fazer login, a tela fica "processando" e não mostra nada.

## Possíveis Causas

### 1. Erro JavaScript no Console do Navegador
**Solução:** Abra o Console do navegador (F12) e verifique se há erros em vermelho.

### 2. API `/auth/validate_token` falhando
Após o login, o frontend chama esta API para validar o token.

**Para testar:**
```bash
# No terminal, teste a API manualmente
curl -H "access-token: SEU_TOKEN" http://localhost:3000/auth/validate_token
```

### 3. API `/api/v1/conversations.json` falhando ou muito lenta
Esta API carrega as conversas do usuário.

**Para testar:**
```bash
curl -H "access-token: SEU_TOKEN" http://localhost:3000/api/v1/conversations.json?type=0&page=1
```

### 4. Dados YAML corrompidos em colunas serializadas
Algumas tabelas podem ter dados YAML corrompidos que causam erro ao deserializar.

**Para verificar:**
```bash
cd /home/aurelio/FONTES/inbox/chatwoot
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
bundle exec rails runner "
  # Verificar dados em colunas serializadas
  Conversation.find_each do |c|
    begin
      c.attributes # força deserialização
    rescue => e
      puts \"ERRO Conversation #{c.id}: #{e.message}\"
    end
  end
"
```

### 5. Problema com Vite não servindo assets
Verifique se o Vite está rodando:
```bash
ps aux | grep vite
curl http://localhost:3036/vite-dev/@vite/client
```

## Soluções Rápidas

### Desabilitar Mini Profiler (pode estar causando problemas)
Adicione ao `.env`:
```
DISABLE_MINI_PROFILER=true
```

### Limpar cache do navegador
- Pressione Ctrl+Shift+Delete
- Limpe cache e cookies
- Recarregue a página

### Verificar logs em tempo real
```bash
tail -f /home/aurelio/FONTES/inbox/chatwoot/log/development.log
```

E tente fazer login novamente para ver os erros em tempo real.

