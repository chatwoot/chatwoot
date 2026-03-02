# frozen_string_literal: true

class Saas::KnowledgeDocumentPolicy < ApplicationPolicy
  def create?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end
end
