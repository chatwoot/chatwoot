# frozen_string_literal: true

namespace :embed do
  desc 'Gera URL de embed para um usuário'
  task :generate_url, [:user_id, :account_id, :inbox_id, :note] => :environment do |_t, args|
    user_id = args[:user_id]&.to_i
    account_id = args[:account_id]&.to_i
    inbox_id = args[:inbox_id]&.to_i if args[:inbox_id].present?
    note = args[:note] || 'Gerado via rake task'

    unless user_id && account_id
      puts 'Uso: rake embed:generate_url[user_id,account_id,inbox_id,note]'
      puts 'Exemplo: rake embed:generate_url[123,1,456,"Embed para cliente X"]'
      exit 1
    end

    user = User.find_by(id: user_id)
    account = Account.find_by(id: account_id)
    inbox = inbox_id ? Inbox.find_by(id: inbox_id, account_id: account_id) : nil

    unless user && account && AccountUser.exists?(user: user, account: account)
      puts "Erro: Usuário ou conta não encontrados"
      exit 1
    end

    result = EmbedTokenService.generate(
      user: user,
      account: account,
      inbox: inbox,
      created_by: user,
      note: note
    )

    puts "\n✅ URL de Embed gerada!"
    puts "Token ID: #{result[:embed_token].id}"
    puts "Usuário: #{user.email}"
    puts "Conta: #{account.name}"
    puts "Inbox: #{inbox ? inbox.name : 'Todas'}"
    puts "\n🔗 URL:"
    puts result[:embed_url]
    puts "\n"
  end

  desc 'Lista todos os embed tokens de uma conta'
  task :list, [:account_id] => :environment do |_t, args|
    account_id = args[:account_id]&.to_i
    unless account_id
      puts 'Uso: rake embed:list[account_id]'
      exit 1
    end
    account = Account.find_by(id: account_id)
    unless account
      puts "Conta não encontrada"
      exit 1
    end
    tokens = account.embed_tokens.includes(:user, :inbox).order(created_at: :desc)
    tokens.each do |token|
      puts "ID: #{token.id} | Usuário: #{token.user.email} | Inbox: #{token.inbox&.name || 'Todas'} | #{token.revoked? ? 'REVOGADO' : 'ATIVO'}"
    end
  end

  desc 'Revoga um embed token'
  task :revoke, [:token_id] => :environment do |_t, args|
    token_id = args[:token_id]&.to_i
    unless token_id
      puts 'Uso: rake embed:revoke[token_id]'
      exit 1
    end
    token = EmbedToken.find_by(id: token_id)
    unless token
      puts "Token não encontrado"
      exit 1
    end
    EmbedTokenService.revoke(token)
    puts "Token #{token_id} revogado"
  end
end
