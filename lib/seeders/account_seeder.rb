## Class to generate sample data for a chatwoot test Account.
############################################################
### Usage #####
#
#   # Seed an account with all data types in this class
#   Seeders::AccountSeeder.new(account: account).seed!
#
#   # When you want to seed only a specific type of data
#   Seeders::AccountSeeder.new(account: account).seed_canned_responses
#   # Seed specific number of objects
#   Seeders::AccountSeeder.new(account: account).seed_canned_responses(count: 10)
#
############################################################

class Seeders::AccountSeeder
  pattr_initialize [:account!]

  def seed!
    seed_canned_responses
  end

  def seed_canned_responses(count: 50)
    count.times do
      account.canned_responses.create(content: Faker::Quote.fortune_cookie, short_code: Faker::Alphanumeric.alpha(number: 10))
    end
  end
end
