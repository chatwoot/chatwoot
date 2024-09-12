class ChatbotPolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator?
  end

  def create_chatbot?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def destroy_chatbot?
    @account_user.administrator?
  end

  def retrain_chatbot?
    @account_user.administrator?
  end
end
