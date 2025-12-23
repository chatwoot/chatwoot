# Como Gerar URL de Embed Diretamente no Banco/Rails Console

Sim, é possível gerar URLs de embed fazendo operações diretas no banco de dados através do Rails console, sem precisar usar a API.

## Método 1: Usando Rake Task (Recomendado)

Criei uma rake task que facilita a geração:

```bash
# Gerar URL de embed
rake embed:generate_url[user_id,account_id,inbox_id,note]

# Exemplo:
rake embed:generate_url[1,1,,"Embed para cliente X"]

# Listar todos os tokens de uma conta
rake embed:list[account_id]

# Revogar um token
rake embed:revoke[token_id]
```

## Método 2: Diretamente no Rails Console

Abra o Rails console:

```bash
bin/rails console
```

### Gerar URL de Embed

```ruby
# 1. Buscar usuário e conta
user = User.find_by(email: 'usuario@exemplo.com')
account = Account.find(1) # ou Account.find_by(name: 'Nome da Conta')
inbox = Inbox.find(1) # Opcional: nil para todas as inboxes

# 2. Gerar o token e URL usando o serviço
result = EmbedTokenService.generate(
  user: user,
  account: account,
  inbox: inbox, # ou nil para todas
  created_by: user, # ou outro usuário admin
  note: 'Embed gerado manualmente'
)

# 3. A URL está em result[:embed_url]
puts result[:embed_url]

# Exemplo de saída:
# http://localhost:3000/embed/auth?token=eyJhbGciOiJIUzI1NiJ9...
```

### Verificar Tokens Existentes

```ruby
# Listar todos os tokens de uma conta
account = Account.find(1)
tokens = account.embed_tokens.includes(:user, :inbox).order(created_at: :desc)

tokens.each do |token|
  puts "ID: #{token.id}"
  puts "  Usuário: #{token.user.email}"
  puts "  Inbox: #{token.inbox&.name || 'Todas'}"
  puts "  Status: #{token.revoked? ? 'REVOGADO' : 'ATIVO'}"
  puts "  Criado em: #{token.created_at}"
  puts "  Usado: #{token.usage_count} vezes"
  puts "---"
end
```

### Revogar um Token

```ruby
token = EmbedToken.find(1)
EmbedTokenService.revoke(token)
# ou diretamente:
token.revoke!
```

### Gerar URL a partir de um Token Existente

Se você já tem um token no banco e quer gerar a URL novamente:

```ruby
token = EmbedToken.find(1)

# Você precisa recriar o JWT manualmente
require 'jwt'
require 'securerandom'

jwt_secret = ENV.fetch('JWT_SECRET', Rails.application.secret_key_base)
payload = {
  sub: token.user_id,
  account_id: token.account_id,
  jti: token.jti,
  aud: 'embed',
  iss: 'synkicrm',
  iat: Time.now.to_i
}
payload[:inbox_id] = token.inbox_id if token.inbox_id

jwt_token = JWT.encode(payload, jwt_secret, 'HS256')
base_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
embed_url = "#{base_url}/embed/auth?token=#{jwt_token}"

puts embed_url
```

## Método 3: SQL Direto (Não Recomendado)

Embora seja tecnicamente possível inserir diretamente no banco via SQL, **NÃO é recomendado** porque:

1. Você precisa gerar o JWT manualmente (requer a chave secreta)
2. Precisa gerar um UUID único para `jti`
3. Precisa calcular o `token_digest` (SHA256 do jti)
4. Pode quebrar validações e relacionamentos

**Use sempre o Rails console ou rake task** para garantir integridade dos dados.

## Exemplo Completo

```ruby
# No Rails console
user = User.find_by(email: 'cliente@exemplo.com')
account = Account.find(1)
inbox = Inbox.find_by(account: account, name: 'Suporte')

result = EmbedTokenService.generate(
  user: user,
  account: account,
  inbox: inbox,
  created_by: User.find_by(role: 'administrator'),
  note: 'Embed para dashboard do cliente'
)

puts "✅ Token criado!"
puts "ID: #{result[:embed_token].id}"
puts "URL: #{result[:embed_url]}"
```

## Notas Importantes

- Os tokens **não expiram automaticamente** - você precisa revogá-los manualmente
- Cada token pode ser usado múltiplas vezes
- O token é vinculado ao usuário e conta específicos
- Se especificar `inbox`, o embed mostrará apenas essa inbox
- Se `inbox` for `nil`, o embed mostrará todas as conversas do usuário na conta
