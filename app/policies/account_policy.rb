class AccountPolicy < ApplicationPolicy
  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def cache_keys?
    @account_user.administrator? || @account_user.agent?
  end

  def limits?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def update_active_at?
    true
  end

  def clear_billing_cache?
    true
  end

  def delete_messages_with_source_id?
    true
  end

  def unassigned_conversations_assignment?
    true
  end

  def create_one_click_conversations?
    true
  end

  def subscription?
    @account_user.administrator?
  end

  def checkout?
    @account_user.administrator?
  end
end
