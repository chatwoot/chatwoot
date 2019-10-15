# frozen_string_literal: true

class Reports::UpdateAccountIdentity < Reports::UpdateIdentity
  attr_reader :account

  def initialize(account, timestamp = Time.now)
    super(account, timestamp)
    @identity = ::AccountIdentity.new(account.id)
  end
end
