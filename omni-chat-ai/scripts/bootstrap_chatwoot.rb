# Idempotent first-run bootstrap for Chatwoot, run via `rails runner`.
# Ensures an account + administrator exist and prints the admin's API access token plus the
# account id, which deploy.sh captures into .env so the AI service can auto-provision channels.
#
#   docker compose exec -T chatwoot bundle exec rails runner "$(cat scripts/bootstrap_chatwoot.rb)"

email = ENV.fetch('OMNI_ADMIN_EMAIL', 'admin@omni-chat-ai.local')
password = ENV.fetch('OMNI_ADMIN_PASSWORD', 'OmniChatAI!123')

account = Account.first || Account.create!(name: 'Omni-Chat-AI')

user = User.find_by(email: email)
if user.nil?
  user = User.new(name: 'Admin', email: email, password: password, type: 'SuperAdmin')
  user.skip_confirmation!
  user.save!
end

unless AccountUser.exists?(account_id: account.id, user_id: user.id)
  AccountUser.create!(account_id: account.id, user_id: user.id, role: :administrator)
end

# AccessTokenable auto-creates a token on user creation.
token = user.reload.access_token&.token

puts "OMNI_BOOTSTRAP account_id=#{account.id} token=#{token}"
