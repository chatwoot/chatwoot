## 💻 OPCIÓN 2: Instalación Local Windows

### Prerrequisitos Detallados

#### 1. Windows Subsystem for Linux (WSL2) - RECOMENDADO

```powershell
# Ejecutar como Administrador
wsl --install
# Reiniciar Windows
wsl --set-default-version 2
```

#### 2. Ruby con rbenv (en WSL2)

```bash
# Dentro de WSL2 Ubuntu
sudo apt update && sudo apt upgrade -y

# Instalar dependencias
sudo apt install -y curl git zlib1g-dev build-essential libssl-dev \
  libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev \
  libxslt1-dev libcurl4-openssl-dev software-properties-common \
  libffi-dev postgresql-client

# Instalar rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Configurar shell
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Instalar Ruby 3.4.4
rbenv install 3.4.4
rbenv global 3.4.4
ruby -v
```

#### 3. Node.js 23.x

```bash
# Instalar nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

# Instalar Node.js 23
nvm install 23
nvm use 23
nvm alias default 23

# Instalar pnpm
npm install -g pnpm@10
```

#### 4. PostgreSQL con pgvector

```bash
# Instalar PostgreSQL
sudo apt install -y postgresql postgresql-contrib postgresql-server-dev-all

# Iniciar servicio
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Crear usuario
sudo -u postgres createuser -s $USER
sudo -u postgres createdb $USER

# Instalar pgvector
git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git /tmp/pgvector
cd /tmp/pgvector
make
sudo make install
```

#### 5. Redis

```bash
# Instalar Redis
sudo apt install -y redis-server

# Configurar e iniciar
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verificar
redis-cli ping
```

### Configuración del Proyecto

#### 1. Configurar Variables de Entorno

```bash
# En el directorio del proyecto
cp .env.example .env

# Editar .env con valores locales
nano .env
```

**Configuraciones clave en .env:**
```bash
# Base de datos
POSTGRES_HOST=localhost
POSTGRES_USERNAME=tu_usuario
POSTGRES_PASSWORD=
POSTGRES_DATABASE=chatwoot_development

# Redis
REDIS_URL=redis://localhost:6379

# URLs
FRONTEND_URL=http://localhost:3000
FORCE_SSL=false

# Email (desarrollo)
SMTP_DOMAIN=localhost
SMTP_PORT=1025
SMTP_ADDRESS=localhost
```

#### 2. Instalar Dependencias

```bash
# Instalar gems Ruby
bundle install

# Instalar dependencias Node.js
pnpm install
```

#### 3. Configurar Base de Datos

```bash
# Crear bases de datos
bundle exec rails db:create

# Ejecutar migraciones
bundle exec rails db:migrate

# Cargar datos de ejemplo (opcional)
bundle exec rails db:seed
```

#### 4. Configurar Mailhog (opcional para emails)

```bash
# Instalar Mailhog para testing de emails
sudo wget -O /usr/local/bin/mailhog \
  https://github.com/mailhog/MailHog/releases/download/v1.0.1/MailHog_linux_amd64
sudo chmod +x /usr/local/bin/mailhog

# Ejecutar en background
mailhog > /dev/null 2>&1 &
```

### Comandos de Desarrollo Local

```bash
# Opción 1: Usar overmind (recomendado)
overmind start -f Procfile.dev

# Opción 2: Usar foreman
foreman start -f Procfile.dev

# Opción 3: Ejecutar servicios manualmente en terminales separadas

# Terminal 1: Rails server
bundle exec rails server -p 3000

# Terminal 2: Vite dev server
bin/vite dev

# Terminal 3: Sidekiq workers
bundle exec sidekiq -C config/sidekiq.yml

# Terminal 4: Mailhog (si instalaste)
mailhog
```

### Verificación de Instalación Local

```bash
# Verificar servicios
bundle exec rails runner "puts 'Rails OK: ' + Rails.env"
pnpm --version
redis-cli ping
psql -c "SELECT version();" -d chatwoot_development

# Verificar aplicación
curl http://localhost:3000/api/v1/health
```

---

## 🔧 Comandos Útiles de Desarrollo

### Testing

```bash
# Backend tests (RSpec)
bundle exec rspec

# Frontend tests (Vitest)
pnpm test

# Lint y formato
bundle exec rubocop -a        # Ruby
pnpm eslint:fix              # JavaScript/Vue
```

### Base de Datos

```bash
# Reset completo
bundle exec rails db:drop db:create db:migrate db:seed

# Solo migraciones
bundle exec rails db:migrate

# Rollback
bundle exec rails db:rollback
```

### Debugging

```bash
# Logs de Rails
tail -f log/development.log

# Logs de Sidekiq
tail -f log/sidekiq.log

# Console Rails
bundle exec rails console
```

---

## 🚀 Siguientes Pasos

### 1. Crear Cuenta de Administrador

```bash
# En rails console
bundle exec rails console

# Crear super admin
account = Account.create!(name: 'Mi Empresa')
user = User.create!(
  email: 'admin@miempresa.com',
  password: 'mi_password_segura',
  name: 'Admin Principal',
  account: account,
  role: 'administrator'
)
```

### 2. Acceder a la Aplicación

1. Abrir navegador en `http://localhost:3000`
2. Hacer login con las credenciales creadas
3. Explorar dashboard y configurar primera inbox

### 3. Configuración Inicial

- **Configurar primera inbox** (canal de comunicación)
- **Personalizar configuración de cuenta**
- **Crear usuarios adicionales si necesario**
- **Probar envío de emails** (usando Mailhog)

