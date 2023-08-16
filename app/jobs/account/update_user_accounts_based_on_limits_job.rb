class Account::UpdateUserAccountsBasedOnLimitsJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    puts 'id': account_id
    account = Account.find(account_id)
    allowed_no_of_users = account.usage_limits[:agents]
    allowed_chat_history = account.usage_limits[:history]
    restrict_agent(account, allowed_no_of_users)
    # restrict_history(account,allowed_chat_history)
  end

  def restrict_agent(account, allowed_no_of_users)
    no_of_user = account.account_users.count
    if allowed_no_of_users.present? && (no_of_user > allowed_no_of_users.to_i)
      difference = no_of_user - allowed_no_of_users.to_i
      agents_count = account.agents.count
      if difference >= agents_count
        account.agents.each do |agent|
          agent.account_users.update_all(is_deleted: true)
        end
        account.agents.update_all(is_deleted: true)
        delete_admins(account, difference - agents_count)
      else
        delete_agents(account, difference)
      end

    elsif no_of_user < allowed_no_of_users.to_i
      difference = allowed_no_of_users.to_i - no_of_user
      AccountUser.unscoped.where(account_id: account.id, is_deleted: true).limit(difference).each do |account_user|
        User.unscoped.find(account_user.user_id).update!(is_deleted: false)
        account_user.update!(is_deleted: false)
      end
    end
  end

  def restrict_history(account, allowed_chat_history)
    if allowed_chat_history.nil?
      retrieve_all_messages(account.id)
    else
      threshold_date = allowed_chat_history.days.ago.beginning_of_day + 1.day
      retrieve_messages(account.id, threshold_date)
      hide_messages(account.id, threshold_date)
    end
  end

  def delete_admins(account, no_of_users)
    account.account_users.where.not(inviter_id: nil).limit(no_of_users).each do |account_user|
      account_user.update(is_deleted: true)
      account_user.user.update(is_deleted: true)
    end
  end

  def delete_agents(account, no_of_users)
    account.agents.limit(no_of_users).each do |agent|
      agent.update(is_deleted: true)
      agent.account_users.update_all(is_deleted: true)
    end
  end

  def retrieve_all_messages(id)
    hidden_messages = HiddenMessage.where('account_id = ?', id)
    puts 'hidden_message': hidden_messages
    hidden_messages.each do |hidden_message|
      hidden_message.retrieve unless Message.exists?(created_at: hidden_message.created_at)
    end
    Rails.cache.clear
  end

  def retrieve_messages(id, threshold_date)
    hidden_messages = HiddenMessage.where('account_id = ? AND created_at > ?', id, threshold_date)
    puts 'hidden_messages': hidden_messages
    hidden_messages.each do |hidden_message|
      hidden_message.retrieve unless Message.exists?(created_at: hidden_message.created_at)
    end
    Rails.cache.clear
  end

  def hide_messages(id, threshold_date)
    messages_to_hide = Message.where('account_id = ? AND created_at <= ?', id, threshold_date)
    puts 'messages_to_hide': messages_to_hide
    messages_to_hide.each do |message|
      message.hide unless HiddenMessage.exists?(created_at: message.created_at)
    end
    Rails.cache.clear
  end
end
