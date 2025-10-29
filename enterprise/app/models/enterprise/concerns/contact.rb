module Enterprise::Concerns::Contact
  extend ActiveSupport::Concern
  included do
    belongs_to :company, optional: true
  end
end
