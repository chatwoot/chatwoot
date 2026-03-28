#!/bin/bash
echo "🔄 Reset completo do Chatwoot..."

# Parar tudo
docker-compose down -v
echo "✓ Containers parados e volumes removidos"

# Limpar imagens (opcional)
# docker rmi chatwoot:development chatwoot-rails:development chatwoot-vite:development 2>/dev/null

# Subir apenas infraestrutura
docker-compose up -d postgres redis mailhog
echo "✓ Infraestrutura iniciada"

sleep 10

# Build e subir aplicação
docker-compose up -d rails sidekiq vite
echo "✓ Aplicação iniciada"

sleep 15

# Criar banco
docker-compose exec -T rails bundle exec rails db:create db:migrate
echo "✓ Banco criado e migrado"

# Criar admin
docker-compose exec -T rails bundle exec rails runner "
user = User.create!(email: 'admin@example.com', password: 'Password123!', password_confirmation: 'Password123!', name: 'Admin', confirmed_at: Time.current)
account = Account.create!(name: 'Acme Inc')
AccountUser.create!(account: account, user: user, role: :administrator)
puts 'Admin criado!'
"

echo ""
echo "✅ Setup completo!"
echo "   URL: http://localhost:3000"
echo "   Email: admin@example.com"
echo "   Senha: Password123!"
