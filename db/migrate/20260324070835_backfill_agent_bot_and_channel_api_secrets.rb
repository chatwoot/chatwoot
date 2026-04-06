class BackfillAgentBotAndChannelApiSecrets < ActiveRecord::Migration[7.1]
  def up
    AgentBot.where(secret: nil).find_each do |agent_bot|
      agent_bot.update!(secret: SecureRandom.urlsafe_base64(24))
    end

    Channel::Api.where(secret: nil).find_each do |channel|
      channel.update!(secret: SecureRandom.urlsafe_base64(24))
    end
  end

  def down
    # no-op: removing the columns in the previous migrations handles cleanup
  end
end
