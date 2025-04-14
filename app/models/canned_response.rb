# == Schema Information
#
# Table name: canned_responses
#
#  id         :integer          not null, primary key
#  content    :text
#  short_code :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer          not null
#

class CannedResponse < ApplicationRecord
  validates :content, presence: true
  validates :short_code, presence: true
  validates :account, presence: true
  validates :short_code, uniqueness: { scope: :account_id }

  belongs_to :account
  has_many :messages, dependent: :destroy
  has_many :canned_response_inboxes, dependent: :destroy
  has_many :inboxes, through: :canned_response_inboxes

  scope :order_by_search, lambda { |search|
    short_code_starts_with = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 1', "#{search}%"])
    short_code_like = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 0.5', "%#{search}%"])
    content_like = sanitize_sql_array(['WHEN content ILIKE ? THEN 0.2', "%#{search}%"])

    order_clause = "CASE #{short_code_starts_with} #{short_code_like} #{content_like} ELSE 0 END"

    order(Arel.sql(order_clause) => :desc)
  }

  scope :by_inbox, lambda { |inbox_id|
    return all if inbox_id.blank?

    left_joins(:inboxes).where(inboxes: { id: [inbox_id, nil] })
  }

  scope :search, lambda { |search|
    return all if search.blank?

    where('short_code ILIKE :search OR content ILIKE :search', search: "%#{search}%")
      .order_by_search(search)
  }

  def messages_count
    messages.count
  end
end
