<img src="./.github/screenshots/header.png#gh-light-mode-only" width="100%" alt="Header light mode"/>
<img src="./.github/screenshots/header-dark.png#gh-dark-mode-only" width="100%" alt="Header dark mode"/>

___

# Chatwoot

The modern customer support platform, an open-source alternative to Intercom, Zendesk, Salesforce Service Cloud etc.

<p>
  <a href="https://codeclimate.com/github/chatwoot/chatwoot/maintainability"><img src="https://api.codeclimate.com/v1/badges/e6e3f66332c91e5a4c0c/maintainability" alt="Maintainability"></a>
  <img src="https://img.shields.io/circleci/build/github/chatwoot/chatwoot" alt="CircleCI Badge">
    <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/pulls/chatwoot/chatwoot" alt="Docker Pull Badge"></a>
  <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/cloud/build/chatwoot/chatwoot" alt="Docker Build Badge"></a>
  <img src="https://img.shields.io/github/commit-activity/m/chatwoot/chatwoot" alt="Commits-per-month">
  <a title="Crowdin" target="_self" href="https://chatwoot.crowdin.com/chatwoot"><img src="https://badges.crowdin.net/e/37ced7eba411064bd792feb3b7a28b16/localized.svg"></a>
  <a href="https://discord.gg/cJXdrwS"><img src="https://img.shields.io/discord/647412545203994635" alt="Discord"></a>
  <a href="https://status.chatwoot.com"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fchatwoot%2Fstatus%2Fmaster%2Fapi%2Fchatwoot%2Fuptime.json" alt="uptime"></a>
  <a href="https://status.chatwoot.com"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fchatwoot%2Fstatus%2Fmaster%2Fapi%2Fchatwoot%2Fresponse-time.json" alt="response time"></a>
  <a href="https://artifacthub.io/packages/helm/chatwoot/chatwoot"><img src="https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/artifact-hub" alt="Artifact HUB"></a>
</p>


<p>
  <a href="https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master" alt="Deploy to Heroku">
     <img width="150" alt="Deploy" src="https://www.herokucdn.com/deploy/button.svg"/>
  </a>
  <a href="https://marketplace.digitalocean.com/apps/chatwoot?refcode=f2238426a2a8" alt="Deploy to DigitalOcean">
     <img width="200" alt="Deploy to DO" src="https://www.deploytodo.com/do-btn-blue.svg"/>
  </a>
</p>

<img src="./.github/screenshots/dashboard.png#gh-light-mode-only" width="100%" alt="Chat dashboard dark mode"/>
<img src="./.github/screenshots/dashboard-dark.png#gh-dark-mode-only" width="100%" alt="Chat dashboard"/>

---

Chatwoot is the modern, open-source, and self-hosted customer support platform designed to help businesses deliver exceptional customer support experience. Built for scale and flexibility, Chatwoot gives you full control over your customer data while providing powerful tools to manage conversations across channels.

### ✨ Captain – AI Agent for Support

Supercharge your support with Captain, Chatwoot’s AI agent. Captain helps automate responses, handle common queries, and reduce agent workload—ensuring customers get instant, accurate answers. With Captain, your team can focus on complex conversations while routine questions are resolved automatically. Read more about Captain [here](https://chwt.app/captain-docs).

### 💬 Omnichannel Support Desk

Chatwoot centralizes all customer conversations into one powerful inbox, no matter where your customers reach out from. It supports live chat on your website, email, Facebook, Instagram, Twitter, WhatsApp, Telegram, Line, SMS etc.

### 📚 Help center portal

Publish help articles, FAQs, and guides through the built-in Help Center Portal. Enable customers to find answers on their own, reduce repetitive queries, and keep your support team focused on more complex issues.

### 🗂️ Other features

#### Collaboration & Productivity

- Private Notes and @mentions for internal team discussions.
- Labels to organize and categorize conversations.
- Keyboard Shortcuts and a Command Bar for quick navigation.
- Canned Responses to reply faster to frequently asked questions.
- Auto-Assignment to route conversations based on agent availability.
- Multi-lingual Support to serve customers in multiple languages.
- Custom Views and Filters for better inbox organization.
- Business Hours and Auto-Responders to manage response expectations.
- Teams and Automation tools for scaling support workflows.
- Agent Capacity Management to balance workload across the team.

#### Customer Data & Segmentation
- Contact Management with profiles and interaction history.
- Contact Segments and Notes for targeted communication.
- Campaigns to proactively engage customers.
- Custom Attributes for storing additional customer data.
- Pre-Chat Forms to collect user information before starting conversations.

#### Integrations
- Slack Integration to manage conversations directly from Slack.
- Dialogflow Integration for chatbot automation.
- Dashboard Apps to embed internal tools within Chatwoot.
- Shopify Integration to view and manage customer orders right within Chatwoot.
- Use Google Translate to translate messages from your customers in realtime.
- Create and manage Linear tickets within Chatwoot.

#### Reports & Insights
- Live View of ongoing conversations for real-time monitoring.
- Conversation, Agent, Inbox, Label, and Team Reports for operational visibility.
- CSAT Reports to measure customer satisfaction.
- Downloadable Reports for offline analysis and reporting.


## Documentation

Detailed documentation is available at [chatwoot.com/help-center](https://www.chatwoot.com/help-center).

## Translation process

The translation process for Chatwoot web and mobile app is managed at [https://translate.chatwoot.com](https://translate.chatwoot.com) using Crowdin. Please read the [translation guide](https://www.chatwoot.com/docs/contributing/translating-chatwoot-to-your-language) for contributing to Chatwoot.

## Branching model

We use the [git-flow](https://nvie.com/posts/a-successful-git-branching-model/) branching model. The base branch is `develop`.
If you are looking for a stable version, please use the `master` or tags labelled as `v1.x.x`.

## Deployment

### Docker (Local Development)

Для запуска Chatwoot локально с базами данных в Docker выполните следующие шаги:

#### Подготовка

1. Убедитесь что у вас установлены:
   - Docker и Docker Compose
   - Ruby 3.3+
   - Node.js 18+
   - pnpm

2. Склонируйте репозиторий:
   ```bash
   git clone https://github.com/chatwoot/chatwoot.git
   cd chatwoot
   ```

#### Запуск баз данных в Docker

1. Запустите только базы данных и MailHog:
   ```bash
   docker-compose -f docker-compose.dev.yaml up -d
   ```

2. Проверьте что сервисы запущены:
   ```bash
   docker-compose -f docker-compose.dev.yaml ps
   ```

#### Настройка локального приложения

1. Создайте файл `.env`:
   ```bash
   # Chatwoot Configuration
   NODE_ENV=development
   RAILS_ENV=development

   # Database Configuration
   POSTGRES_HOST=localhost
   POSTGRES_PORT=5433
   POSTGRES_DB=chatwoot
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=chatwoot_password

   # Redis Configuration
   REDIS_URL=redis://localhost:6380
   REDIS_PASSWORD=

   # Frontend Configuration
   FRONTEND_URL=http://localhost:3000

   # Email Configuration (using MailHog for development)
   SMTP_DOMAIN=localhost
   SMTP_PORT=1025
   SMTP_ADDRESS=localhost
   SMTP_USERNAME=
   SMTP_PASSWORD=
   SMTP_AUTHENTICATION=
   FORCE_SSL=false

   # Application Configuration
   SECRET_KEY_BASE=your_secret_key_base_here_minimum_30_characters
   INSTALLATION_ENV=docker

   # Disable Enterprise features for OSS version
   CW_ENTERPRISE_EDITION=false
   DISABLE_ENTERPRISE=true

   # Active Storage Configuration
   ACTIVE_STORAGE_SERVICE=local

   # Default settings
   DEFAULT_LOCALE=en
   ```

2. Установите зависимости:
   ```bash
   # Ruby зависимости
   bundle install

   # Node.js зависимости
   pnpm install
   ```

3. Настройте базу данных:
   ```bash
   # Создание и миграции базы данных
   bundle exec rails db:create
   bundle exec rails db:migrate
   bundle exec rails db:seed
   ```

#### Запуск приложения

1. В первом терминале запустите Rails сервер:
   ```bash
   bundle exec rails server
   ```

2. Во втором терминале запустите Sidekiq:
   ```bash
   bundle exec sidekiq -C config/sidekiq.yml
   ```

3. В третьем терминале запустите Vite dev server:
   ```bash
   bin/vite dev
   ```

#### Доступ к приложению

- **Chatwoot**: http://localhost:3000
- **MailHog** (для тестирования email): http://localhost:8025
- **PostgreSQL**: localhost:5433
- **Redis**: localhost:6380

#### Persistent Storage

Данные PostgreSQL и Redis сохраняются в Docker volumes:
- `chatwoot_postgres_data` - данные PostgreSQL
- `chatwoot_redis_data` - данные Redis

При перезапуске Docker контейнеров данные сохранятся.

#### Остановка сервисов

```bash
# Остановка Docker сервисов
docker-compose -f docker-compose.dev.yaml down

# Остановка с удалением volumes (ВНИМАНИЕ: удалит все данные!)
docker-compose -f docker-compose.dev.yaml down -v
```

#### Альтернативный метод: полный Docker запуск

Полный запуск всех сервисов в Docker (исправлены все проблемы с подключениями):

```bash
# 1. Запустите базовые сервисы
docker-compose up -d postgres redis mailhog

# 2. Запустите основные сервисы  
docker-compose up -d rails sidekiq

# 3. (Опционально) Запустите Vite dev server
docker-compose up -d vite

# Проверьте статус всех сервисов
docker-compose ps
```

**Что было исправлено для полного Docker запуска:**
- ✅ Настроены правильные environment переменные для связи между контейнерами
- ✅ Исправлена проблема с `POSTGRES_USER` vs `POSTGRES_USERNAME` в entrypoint скриптах
- ✅ Sidekiq корректно подключается к Redis через `redis://redis:6379`
- ✅ Rails сервер успешно стартует и подключается к PostgreSQL
- ✅ Persistent storage настроен для сохранения данных

#### Troubleshooting

- Если порты 5432 или 6379 заняты, проект использует 5433 и 6380 соответственно
- Для просмотра логов: `docker-compose -f docker-compose.dev.yaml logs <service-name>`
- Для входа в контейнер: `docker-compose -f docker-compose.dev.yaml exec <service-name> bash`
- При проблемах с сетью при сборке Docker образов используйте гибридный подход (базы в Docker, приложение локально)

### Heroku one-click deploy

Deploying Chatwoot to Heroku is a breeze. It's as simple as clicking this button:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master)

Follow this [link](https://www.chatwoot.com/docs/environment-variables) to understand setting the correct environment variables for the app to work with all the features. There might be breakages if you do not set the relevant environment variables.


### DigitalOcean 1-Click Kubernetes deployment

Chatwoot now supports 1-Click deployment to DigitalOcean as a kubernetes app.

<a href="https://marketplace.digitalocean.com/apps/chatwoot?refcode=f2238426a2a8" alt="Deploy to DigitalOcean">
  <img width="200" alt="Deploy to DO" src="https://www.deploytodo.com/do-btn-blue.svg"/>
</a>

### Other deployment options

For other supported options, checkout our [deployment page](https://chatwoot.com/deploy).

## Security

Looking to report a vulnerability? Please refer our [SECURITY.md](./SECURITY.md) file.

## Community

If you need help or just want to hang out, come, say hi on our [Discord](https://discord.gg/cJXdrwS) server.

## Contributors

Thanks goes to all these [wonderful people](https://www.chatwoot.com/docs/contributors):

<a href="https://github.com/chatwoot/chatwoot/graphs/contributors"><img src="https://opencollective.com/chatwoot/contributors.svg?width=890&button=false" /></a>


*Chatwoot* &copy; 2017-2025, Chatwoot Inc - Released under the MIT License.
