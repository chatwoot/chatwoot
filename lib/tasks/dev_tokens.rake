# lib/tasks/dev_tokens.rake
namespace :dev do
  desc 'Print a fresh API token for User.first'
  task token: :environment do
    u = User.first or abort('No users')
    a = Account.first or abort('No accounts')
    AccountUser.find_or_create_by!(account: a, user: u) { |r| r.role = :administrator }
    t = AccessToken.create!(owner: u, token: SecureRandom.hex(32))
    puts t.token
  end
end
