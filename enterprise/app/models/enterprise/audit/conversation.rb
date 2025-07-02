module Enterprise::Audit::Conversation
  extend ActiveSupport::Concern

  included do
    audited only: [], on: [:destroy]
    audited associated_with: :account, except: :updated_at, on: [:create, :update]
  end
end
