class Captain::FaqSuggestionFinder
  def initialize(current_user, current_account)
    @current_user = current_user
    @current_account = current_account
  end

  def perform
    suggestions = @current_account.captain_faq_suggestions
    return suggestions if account_user&.administrator?

    accessible_suggestion_ids = Captain::FaqObservation
                                .where(conversation_id: accessible_conversations.select(:id))
                                .select(:faq_suggestion_id)
    suggestions.where(id: accessible_suggestion_ids)
  end

  private

  def accessible_conversations
    Conversations::PermissionFilterService.new(@current_account.conversations, @current_user, @current_account).perform
  end

  def account_user
    @account_user ||= @current_account.account_users.find_by(user_id: @current_user.id)
  end
end
