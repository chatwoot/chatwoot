# Como Gerar URL de Embed via INSERT Direto no Banco

Este documento explica como gerar URLs de embed fazendo INSERT direto na tabela `embed_tokens` e gerando o JWT token em outro sistema.

## Estrutura da Tabela `embed_tokens`

```sql
CREATE TABLE embed_tokens (
  id BIGSERIAL PRIMARY KEY,
  jti VARCHAR NOT NULL UNIQUE,              -- UUID único
  token_digest VARCHAR NOT NULL UNIQUE,    -- SHA256(jti)
  user_id BIGINT NOT NULL,                 -- ID do usuário
  account_id BIGINT NOT NULL,              -- ID da conta
  inbox_id BIGINT,                         -- ID da inbox (opcional)
  created_by_id BIGINT,                    -- ID do criador (opcional)
  revoked_at TIMESTAMP,                    -- NULL = ativo
  last_used_at TIMESTAMP,
  usage_count INTEGER DEFAULT 0,
  note VARCHAR,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

## Processo Completo

### 1. Gerar os Dados Necessários

Você precisa de:

- `user_id`: ID do usuário no Chatwoot
- `account_id`: ID da conta no Chatwoot
- `inbox_id`: ID da inbox (opcional, pode ser NULL)
- `jti`: UUID v4 único (ex: `550e8400-e29b-41d4-a716-446655440000`)
- `token_digest`: SHA256 hexadecimal do `jti`
- `JWT_SECRET`: Chave secreta do Chatwoot (variável de ambiente `JWT_SECRET` ou `Rails.application.secret_key_base`)
- `FRONTEND_URL`: URL base do frontend (variável de ambiente `FRONTEND_URL` ou padrão: `https://chat.synkicrm.com.br`)

### 2. Fazer o INSERT no Banco

```sql
INSERT INTO embed_tokens (
  jti,
  token_digest,
  user_id,
  account_id,
  inbox_id,
  created_by_id,
  note,
  created_at,
  updated_at
) VALUES (
  '550e8400-e29b-41d4-a716-446655440000',  -- jti (UUID)
  'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',  -- SHA256(jti)
  1,                                       -- user_id
  1,                                       -- account_id
  NULL,                                    -- inbox_id (opcional)
  NULL,                                   -- created_by_id (opcional)
  'Embed gerado via INSERT',               -- note (opcional)
  NOW(),
  NOW()
) RETURNING id, jti;
```

### 3. Gerar o JWT Token

O JWT precisa ser gerado com os seguintes parâmetros:

**Payload:**

```json
{
  "sub": 1, // user_id
  "account_id": 1, // account_id
  "jti": "550e8400-...", // mesmo jti do INSERT
  "aud": "embed", // fixo
  "iss": "synkicrm", // fixo
  "iat": 1704067200, // timestamp atual (Unix)
  "inbox_id": 1 // opcional, apenas se tiver inbox
}
```

**Configuração:**

- Algoritmo: `HS256`
- Secret: `JWT_SECRET` (ou `Rails.application.secret_key_base`)

## Exemplos de Código

### Python

```python
import uuid
import hashlib
import jwt
import time

# Configurações
JWT_SECRET = "sua_chave_secreta_aqui"  # Mesma do Chatwoot
FRONTEND_URL = "https://chat.synkicrm.com.br"  # Ou pegar de ENV
user_id = 1
account_id = 1
inbox_id = None  # ou um ID específico

# 1. Gerar jti e token_digest
jti = str(uuid.uuid4())
token_digest = hashlib.sha256(jti.encode()).hexdigest()

# 2. Fazer INSERT no banco (usando psycopg2, por exemplo)
import psycopg2
conn = psycopg2.connect("dbname=chatwoot user=postgres")
cur = conn.cursor()
cur.execute("""
    INSERT INTO embed_tokens (
        jti, token_digest, user_id, account_id, inbox_id,
        note, created_at, updated_at
    ) VALUES (%s, %s, %s, %s, %s, %s, NOW(), NOW())
    RETURNING id
""", (jti, token_digest, user_id, account_id, inbox_id, "Embed via Python"))
token_id = cur.fetchone()[0]
conn.commit()

# 3. Gerar JWT
payload = {
    "sub": user_id,
    "account_id": account_id,
    "jti": jti,
    "aud": "embed",
    "iss": "synkicrm",
    "iat": int(time.time())
}
if inbox_id:
    payload["inbox_id"] = inbox_id

jwt_token = jwt.encode(payload, JWT_SECRET, algorithm="HS256")

# 4. Construir URL
embed_url = f"{FRONTEND_URL}/embed/auth?token={jwt_token}"
print(f"Token ID: {token_id}")
print(f"URL: {embed_url}")
```

### Node.js

```javascript
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { Client } = require('pg');

// Configurações
const JWT_SECRET = process.env.JWT_SECRET || 'sua_chave_secreta_aqui';
const FRONTEND_URL = process.env.FRONTEND_URL || 'https://chat.synkicrm.com.br';
const user_id = 1;
const account_id = 1;
const inbox_id = null; // ou um ID específico

async function generateEmbedUrl() {
  // 1. Gerar jti e token_digest
  const jti = uuidv4();
  const token_digest = crypto.createHash('sha256').update(jti).digest('hex');

  // 2. Fazer INSERT no banco
  const client = new Client({
    connectionString: 'postgresql://user:password@localhost/chatwoot',
  });
  await client.connect();

  const result = await client.query(
    `
    INSERT INTO embed_tokens (
      jti, token_digest, user_id, account_id, inbox_id,
      note, created_at, updated_at
    ) VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
    RETURNING id
  `,
    [jti, token_digest, user_id, account_id, inbox_id, 'Embed via Node.js']
  );

  const token_id = result.rows[0].id;

  // 3. Gerar JWT
  const payload = {
    sub: user_id,
    account_id: account_id,
    jti: jti,
    aud: 'embed',
    iss: 'synkicrm',
    iat: Math.floor(Date.now() / 1000),
  };

  if (inbox_id) {
    payload.inbox_id = inbox_id;
  }

  const jwt_token = jwt.sign(payload, JWT_SECRET, { algorithm: 'HS256' });

  // 4. Construir URL
  const embed_url = `${FRONTEND_URL}/embed/auth?token=${jwt_token}`;

  console.log(`Token ID: ${token_id}`);
  console.log(`URL: ${embed_url}`);

  await client.end();
  return embed_url;
}

generateEmbedUrl();
```

### PHP

```php
<?php
require 'vendor/autoload.php'; // Composer: firebase/php-jwt

use Firebase\JWT\JWT;
use Ramsey\Uuid\Uuid;

// Configurações
$JWT_SECRET = getenv('JWT_SECRET') ?: 'sua_chave_secreta_aqui';
$FRONTEND_URL = getenv('FRONTEND_URL') ?: 'https://chat.synkicrm.com.br';
$user_id = 1;
$account_id = 1;
$inbox_id = null; // ou um ID específico

// 1. Gerar jti e token_digest
$jti = Uuid::uuid4()->toString();
$token_digest = hash('sha256', $jti);

// 2. Fazer INSERT no banco
$pdo = new PDO('pgsql:host=localhost;dbname=chatwoot', 'user', 'password');
$stmt = $pdo->prepare("
    INSERT INTO embed_tokens (
        jti, token_digest, user_id, account_id, inbox_id,
        note, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())
    RETURNING id
");
$stmt->execute([$jti, $token_digest, $user_id, $account_id, $inbox_id, 'Embed via PHP']);
$token_id = $stmt->fetchColumn();

// 3. Gerar JWT
$payload = [
    'sub' => $user_id,
    'account_id' => $account_id,
    'jti' => $jti,
    'aud' => 'embed',
    'iss' => 'synkicrm',
    'iat' => time()
];

if ($inbox_id) {
    $payload['inbox_id'] = $inbox_id;
}

$jwt_token = JWT::encode($payload, $JWT_SECRET, 'HS256');

// 4. Construir URL
$embed_url = "$FRONTEND_URL/embed/auth?token=$jwt_token";

echo "Token ID: $token_id\n";
echo "URL: $embed_url\n";
?>
```

### SQL (PostgreSQL) - Apenas INSERT, JWT precisa ser gerado externamente

```sql
-- Função para gerar UUID e SHA256
CREATE OR REPLACE FUNCTION generate_embed_token(
  p_user_id BIGINT,
  p_account_id BIGINT,
  p_inbox_id BIGINT DEFAULT NULL,
  p_note TEXT DEFAULT NULL
) RETURNS TABLE(token_id BIGINT, jti TEXT, token_digest TEXT) AS $$
DECLARE
  v_jti TEXT;
  v_token_digest TEXT;
  v_token_id BIGINT;
BEGIN
  -- Gerar UUID
  v_jti := gen_random_uuid()::TEXT;

  -- Calcular SHA256
  v_token_digest := encode(digest(v_jti, 'sha256'), 'hex');

  -- Inserir no banco
  INSERT INTO embed_tokens (
    jti, token_digest, user_id, account_id, inbox_id,
    note, created_at, updated_at
  ) VALUES (
    v_jti, v_token_digest, p_user_id, p_account_id, p_inbox_id,
    p_note, NOW(), NOW()
  ) RETURNING id INTO v_token_id;

  RETURN QUERY SELECT v_token_id, v_jti, v_token_digest;
END;
$$ LANGUAGE plpgsql;

-- Uso:
SELECT * FROM generate_embed_token(1, 1, NULL, 'Embed via SQL');
-- Retorna: token_id, jti, token_digest
-- Você ainda precisa gerar o JWT externamente com esses dados
```

## Obter a Chave Secreta (JWT_SECRET)

A chave secreta pode estar em:

1. **Variável de ambiente `JWT_SECRET`**:

   ```bash
   echo $JWT_SECRET
   ```

2. **Rails secret_key_base** (se `JWT_SECRET` não estiver definido):

   - Development: `config/secrets.yml`
   - Production: `ENV["SECRET_KEY_BASE"]` ou `rails credentials:show`

3. **Consultar diretamente no Rails console**:
   ```ruby
   # No Rails console do Chatwoot
   puts ENV.fetch('JWT_SECRET', Rails.application.secret_key_base)
   ```

## Validações Importantes

Antes de fazer o INSERT, verifique:

1. **Usuário existe e está ativo**:

   ```sql
   SELECT id FROM users WHERE id = ? AND confirmed_at IS NOT NULL;
   ```

2. **Conta existe**:

   ```sql
   SELECT id FROM accounts WHERE id = ?;
   ```

3. **Usuário tem acesso à conta**:

   ```sql
   SELECT id FROM account_users WHERE user_id = ? AND account_id = ?;
   ```

4. **Inbox existe e pertence à conta** (se fornecido):
   ```sql
   SELECT id FROM inboxes WHERE id = ? AND account_id = ?;
   ```

## Exemplo Completo (Python com Validações)

```python
import uuid
import hashlib
import jwt
import time
import psycopg2

def generate_embed_url(user_id, account_id, inbox_id=None, note=None):
    JWT_SECRET = "sua_chave_secreta"
    FRONTEND_URL = "https://chat.synkicrm.com.br"

    conn = psycopg2.connect("dbname=chatwoot user=postgres")
    cur = conn.cursor()

    # Validar usuário e conta
    cur.execute("""
        SELECT u.id, au.id
        FROM users u
        INNER JOIN account_users au ON au.user_id = u.id
        WHERE u.id = %s AND au.account_id = %s AND u.confirmed_at IS NOT NULL
    """, (user_id, account_id))

    if not cur.fetchone():
        raise ValueError("Usuário não encontrado ou sem acesso à conta")

    # Validar inbox se fornecido
    if inbox_id:
        cur.execute("""
            SELECT id FROM inboxes WHERE id = %s AND account_id = %s
        """, (inbox_id, account_id))
        if not cur.fetchone():
            raise ValueError("Inbox não encontrada ou não pertence à conta")

    # Gerar jti e token_digest
    jti = str(uuid.uuid4())
    token_digest = hashlib.sha256(jti.encode()).hexdigest()

    # INSERT
    cur.execute("""
        INSERT INTO embed_tokens (
            jti, token_digest, user_id, account_id, inbox_id,
            note, created_at, updated_at
        ) VALUES (%s, %s, %s, %s, %s, %s, NOW(), NOW())
        RETURNING id
    """, (jti, token_digest, user_id, account_id, inbox_id, note))

    token_id = cur.fetchone()[0]
    conn.commit()

    # Gerar JWT
    payload = {
        "sub": user_id,
        "account_id": account_id,
        "jti": jti,
        "aud": "embed",
        "iss": "synkicrm",
        "iat": int(time.time())
    }
    if inbox_id:
        payload["inbox_id"] = inbox_id

    jwt_token = jwt.encode(payload, JWT_SECRET, algorithm="HS256")
    embed_url = f"{FRONTEND_URL}/embed/auth?token={jwt_token}"

    return {
        "token_id": token_id,
        "jti": jti,
        "embed_url": embed_url
    }
```

## Notas Importantes

1. **JWT_SECRET é crítico**: Sem a chave correta, o token não será válido
2. **jti deve ser único**: Use UUID v4 para garantir unicidade
3. **token_digest é SHA256 do jti**: Deve ser calculado corretamente
4. **iat (issued at)**: Use timestamp Unix atual
5. **aud e iss são fixos**: `"embed"` e `"synkicrm"` respectivamente
6. **inbox_id é opcional**: Se NULL, o embed mostra todas as conversas do usuário

## Testar a URL Gerada

Após gerar a URL, teste em um navegador ou iframe:

```html
<iframe
  src="https://chat.synkicrm.com.br/embed/auth?token=SEU_JWT_TOKEN_AQUI"
  width="100%"
  height="600"
  frameborder="0"
></iframe>
```

Se funcionar, o usuário será autenticado automaticamente e verá suas conversas.

