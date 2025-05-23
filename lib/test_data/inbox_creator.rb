class TestData::InboxCreator
  def self.create_for(account)
    Array.new(TestData::Constants::INBOXES_PER_ACCOUNT) do
      channel = Channel::Api.create!(account: account)
      Inbox.create!(
        account_id: account.id,
        name: "API Inbox #{SecureRandom.hex(4)}",
        channel: channel
      )
    end
  end
end
