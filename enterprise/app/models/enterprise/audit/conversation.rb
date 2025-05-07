module Enterprise::Audit::Conversation
  extend ActiveSupport::Concern

  included do
<<<<<<< HEAD
    audited only: [], on: [:destroy]
=======
    audited associated_with: :account, except: :updated_at, on: [:create, :update]
>>>>>>> 2846cc25b (feat(conversation): add audit logging for conversations)
  end
end
