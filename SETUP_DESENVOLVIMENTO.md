# Setup de Desenvolvimento - Chatwoot Fork

Guia completo para configurar o ambiente de desenvolvimento do nosso fork do Chatwoot.

## 🔧 Pré-requisitos

### Tecnologias Necessárias
- **Ruby:** 3.2.x (verificar `.ruby-version`)
- **Node.js:** 23.x (verificar `.nvmrc`)
- **PNPM:** 10.x (gerenciador de pacotes)
- **PostgreSQL:** 13+ 
- **Redis:** 6+
- **Git:** Para controle de versão

### Ferramentas de Desenvolvimento
- **Docker & Docker Compose:** Para ambiente containerizado
- **Foreman:** Para gerenciar processos
- **VS Code/Cursor:** Editor recomendado

## 🚀 Setup Inicial

### 1. Clone e Configuração do Repositório
```bash
# Clonar o fork (se ainda não clonado)
git clone <seu-repositorio-fork> chatwoot-fork
cd chatwoot-fork

# Configurar upstream
git remote add upstream https://github.com/chatwoot/chatwoot.git

# Instalar dependências Ruby
bundle install

# Instalar dependências JavaScript
pnpm install
```

### 2. Configuração do Banco de Dados

#### Opção A: PostgreSQL Local
```bash
# Instalar PostgreSQL
# Ubuntu/Debian: sudo apt-get install postgresql postgresql-contrib
# macOS: brew install postgresql
# Windows: https://www.postgresql.org/download/windows/

# Criar usuário e banco
sudo -u postgres createuser chatwoot -s
sudo -u postgres createdb chatwoot_development
sudo -u postgres createdb chatwoot_test
```

#### Opção B: Docker (Recomendado)
```bash
# Usar docker-compose para serviços
docker-compose up -d postgres redis
```

### 3. Configuração do Ambiente
```bash
# Copiar arquivo de configuração
cp .env.example .env

# Editar variáveis de ambiente conforme necessário
# DATABASE_URL, REDIS_URL, etc.
```

### 4. Setup da Aplicação
```bash
# Executar migrações
bundle exec rails db:setup

# Popular dados de desenvolvimento (opcional)
bundle exec rails db:seed

# Compilar assets
pnpm run build
```

## 🛠️ Comandos de Desenvolvimento

### Iniciar Servidor de Desenvolvimento
```bash
# Opção 1: Foreman (recomendado)
foreman start -f Procfile.dev

# Opção 2: Overmind (alternativa)
overmind start -f Procfile.dev

# Opção 3: Processos separados
# Terminal 1: Rails
bundle exec rails server

# Terminal 2: Vite (assets)
pnpm run dev

# Terminal 3: Worker (jobs em background)
bundle exec sidekiq
```

### Scripts Úteis
```bash
# Testes
pnpm test                    # Testes JavaScript
bundle exec rspec            # Testes Ruby

# Linting e Formatação
pnpm run eslint:fix         # ESLint JavaScript
bundle exec rubocop -a      # RuboCop Ruby

# Build
pnpm run build              # Build assets para produção
pnpm run story:dev          # Storybook para componentes
```

## 📁 Estrutura do Projeto (Principais Pastas)

```
chatwoot-fork/
├── app/
│   ├── controllers/        # Controllers Rails
│   ├── models/            # Models Rails
│   ├── services/          # Service Objects
│   ├── javascript/        # Frontend Vue.js
│   │   ├── dashboard/     # Dashboard principal
│   │   ├── widget/        # Widget de chat
│   │   └── portal/        # Portal de help center
│   └── views/             # Views Rails
├── config/                # Configurações Rails
├── db/                    # Migrações e seeds
├── spec/                  # Testes Ruby
├── public/                # Assets estáticos
└── docker/                # Configurações Docker
```

## 🔄 Workflow de Desenvolvimento

### Branches
- `develop`: Branch principal upstream
- `fork-customizations`: Branch principal do fork
- `feature/nova-funcionalidade`: Branches de features

### Processo de Desenvolvimento
1. Criar branch a partir de `fork-customizations`
   ```bash
   git checkout fork-customizations
   git pull origin fork-customizations
   git checkout -b feature/minha-funcionalidade
   ```

2. Desenvolver e testar
   ```bash
   # Fazer mudanças
   # Testar localmente
   pnpm test && bundle exec rspec
   ```

3. Commit e push
   ```bash
   git add .
   git commit -m "feat: descrição da funcionalidade"
   git push origin feature/minha-funcionalidade
   ```

4. Merge para fork-customizations

### Sincronização com Upstream
```bash
# Buscar mudanças do upstream
git fetch upstream

# Atualizar develop local
git checkout develop
git merge upstream/develop

# Rebase fork-customizations
git checkout fork-customizations
git rebase develop
```

## 🐛 Troubleshooting

### Problemas Comuns

#### Erro de Dependências Ruby
```bash
bundle install --force
bundle clean --force
```

#### Erro de Dependências JavaScript
```bash
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

#### Problemas de Banco de Dados
```bash
bundle exec rails db:drop db:create db:migrate db:seed
```

#### Assets não carregam
```bash
pnpm run build
bundle exec rails assets:precompile
```

## 🔗 Links Úteis

- [Documentação Oficial Chatwoot](https://www.chatwoot.com/help-center)
- [Guia de Contribuição](https://www.chatwoot.com/docs/contributing-guide)
- [API Documentation](https://www.chatwoot.com/developers/api/)
- [Vue.js Documentation](https://vuejs.org/)
- [Rails Guides](https://guides.rubyonrails.org/)

## 📞 Suporte

Para dúvidas sobre o desenvolvimento:
- Consultar `FORK_CUSTOMIZATIONS.md`
- Verificar issues do repositório upstream
- Documentação interna da equipe

---

**Dica:** Mantenha sempre o arquivo `FORK_CUSTOMIZATIONS.md` atualizado com as mudanças que fizer! 