class InboxFaqCategory < ApplicationRecord
  belongs_to :inbox
  belongs_to :faq_category

  validates :inbox_id, uniqueness: { scope: :faq_category_id }
end
