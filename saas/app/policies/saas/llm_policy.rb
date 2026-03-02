# frozen_string_literal: true

# Headless policy for the LLM controller — no model record, authorizes by role.
class Saas::LlmPolicy < ApplicationPolicy
  def completions?
    @account_user.administrator? || @account_user.agent?
  end

  def embeddings?
    @account_user.administrator? || @account_user.agent?
  end

  def models?
    @account_user.administrator? || @account_user.agent?
  end

  def health?
    @account_user.administrator?
  end
end
