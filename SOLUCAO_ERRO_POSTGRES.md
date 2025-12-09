# Solução: Erro de Conexão com PostgreSQL

## 🔍 Problema Identificado

O erro `ActiveRecord::DatabaseConnectionError` ocorre porque a senha configurada no arquivo `.env` (`chatkivo2025@A`) não corresponde à senha configurada no PostgreSQL local.

## ✅ Soluções Possíveis

### Opção 1: Alterar a senha do PostgreSQL para corresponder ao `.env` (Recomendado)

Execute no terminal WSL:

```bash
# Conectar ao PostgreSQL como superusuário
sudo -u postgres psql

# Dentro do psql, execute:
ALTER USER postgres WITH PASSWORD 'chatkivo2025@A';

# Sair do psql
\q
```

### Opção 2: Alterar o `.env` para usar a senha atual do PostgreSQL

Se você souber a senha atual do PostgreSQL, edite o arquivo `.env` e altere:

```bash
POSTGRES_PASSWORD=sua_senha_atual_aqui
```

### Opção 3: Descobrir/Resetar a senha do PostgreSQL

Se você não souber a senha atual:

1. **Editar o arquivo de configuração do PostgreSQL** para permitir conexões sem senha temporariamente:

```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

2. **Alterar a linha** que contém `local all postgres peer` para `local all postgres trust`:

```
# De:
local   all             postgres                                peer

# Para:
local   all             postgres                                trust
```

3. **Reiniciar o PostgreSQL**:

```bash
sudo systemctl restart postgresql
```

4. **Conectar sem senha e alterar a senha**:

```bash
psql -U postgres
```

Dentro do psql:
```sql
ALTER USER postgres WITH PASSWORD 'chatkivo2025@A';
\q
```

5. **Reverter a mudança no pg_hba.conf** (voltar para `peer` ou `md5`):

```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
# Voltar para: local   all             postgres                                peer
sudo systemctl restart postgresql
```

## 🧪 Testar a Conexão

Após configurar a senha, teste a conexão:

```bash
PGPASSWORD='chatkivo2025@A' psql -h localhost -U postgres -d postgres -c 'SELECT version();'
```

Se funcionar, você verá a versão do PostgreSQL.

## 📝 Verificar Configuração do Banco de Dados

Certifique-se de que o banco de dados existe:

```bash
# Listar bancos de dados
PGPASSWORD='chatkivo2025@A' psql -h localhost -U postgres -l

# Criar o banco de dados se não existir
PGPASSWORD='chatkivo2025@A' psql -h localhost -U postgres -c "CREATE DATABASE chatwoot_dev;"
```

## 🔄 Após Resolver

Depois de configurar a senha corretamente, você pode:

1. **Rodar as migrações**:
```bash
bundle exec rails db:chatwoot_prepare
```

2. **Iniciar o servidor Rails**:
```bash
bundle exec rails s
```

## 📋 Variáveis de Ambiente Importantes

Certifique-se de que seu `.env` tenha pelo menos:

```bash
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=chatkivo2025@A
POSTGRES_DATABASE=chatwoot_dev  # ou deixe vazio para usar o padrão
```

## 🐛 Troubleshooting Adicional

### Se ainda não funcionar:

1. **Verificar se o PostgreSQL está rodando**:
```bash
sudo systemctl status postgresql
```

2. **Verificar se a porta está correta**:
```bash
sudo netstat -tlnp | grep 5432
```

3. **Verificar logs do PostgreSQL**:
```bash
sudo tail -f /var/log/postgresql/postgresql-16-main.log
```

4. **Verificar configuração de autenticação**:
```bash
sudo cat /etc/postgresql/16/main/pg_hba.conf | grep -v "^#"
```

