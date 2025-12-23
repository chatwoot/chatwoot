# Como Rodar o Chatwoot

## ✅ O que já está configurado:

1. ✅ Dependências Node.js instaladas (`pnpm install`)
2. ✅ rbenv instalado e configurado
3. ✅ Arquivo `.env` configurado com o banco de dados remoto:
   - Host: 100.86.190.37
   - Porta: 5433
   - Database: chatwoot
   - User: postgres

## ⚠️ O que precisa ser feito (requer sudo):

### Opção 1: Executar o script automático

```bash
bash INSTALL_EVERYTHING.sh
```

Este script vai pedir sua senha sudo e instalar tudo automaticamente.

### Opção 2: Instalar manualmente

1. **Instalar dependências do sistema:**

```bash
sudo apt update
sudo apt install -y \
  build-essential \
  libssl-dev \
  libyaml-dev \
  libreadline-dev \
  zlib1g-dev \
  libncurses5-dev \
  libffi-dev \
  libgdbm-dev \
  libpq-dev
```

2. **Instalar Ruby 3.4.4:**

```bash
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
rbenv install 3.4.4
rbenv local 3.4.4
```

3. **Instalar dependências Ruby:**

```bash
bundle install
```

4. **Configurar banco de dados:**

```bash
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed
```

5. **Iniciar o sistema:**

```bash
pnpm dev
```

## 📝 Notas:

- O arquivo `.env` já está configurado e será carregado automaticamente
- O sistema vai rodar em `http://localhost:3000`
- O banco de dados remoto já está configurado, não precisa instalar PostgreSQL localmente
