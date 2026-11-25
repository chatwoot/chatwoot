namespace :livechat do
  desc 'Import the LiveChat archive: ACCOUNT_ID=1 INBOX_ID=2 [DIR=livechat_export]'
  task import: :environment do
    account = Account.find(ENV.fetch('ACCOUNT_ID'))
    LivechatImport.new(account: account, inbox: account.inboxes.find(ENV.fetch('INBOX_ID')),
                       dir: ENV.fetch('DIR', Rails.root.join('livechat_export'))).perform
  end
end
