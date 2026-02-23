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
  enum visibility: { public_response: 0, private_response: 1 }

  belongs_to :account
  belongs_to :created_by, class_name: 'User', optional: true
  has_many :canned_response_scopes, dependent: :destroy

  validates :content, presence: true
  validates :short_code, presence: true
  validates :account, presence: true
  validates :short_code, uniqueness: { scope: :account_id }

  scope :order_by_search, lambda { |search|
    short_code_starts_with = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 1', "#{search}%"])
    short_code_like = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 0.5', "%#{search}%"])
    content_like = sanitize_sql_array(['WHEN content ILIKE ? THEN 0.2', "%#{search}%"])
    order_clause = "CASE #{short_code_starts_with} #{short_code_like} #{content_like} ELSE 0 END"
    order(Arel.sql(order_clause) => :desc)
  }

  scope :accessible_to, lambda { |user, inbox_id: nil|
    private_accessible_ids = where(visibility: :private_response)
                             .joins(:canned_response_scopes)
                             .where(
                               'canned_response_scopes.user_ids @> ARRAY[:user_id]::integer[]',
                               user_id: user.id
                             )
                             .then do |scope|
                               if inbox_id.present?
                                 scope.where(
                                   "canned_response_scopes.inbox_ids = '{}' OR " \
                                   'canned_response_scopes.inbox_ids @> ARRAY[:inbox_id]::integer[]',
                                   inbox_id: inbox_id
                                 )
                               else
                                 scope
                               end
                             end
                             .distinct.pluck(:id)

    where(visibility: :public_response).or(where(id: private_accessible_ids))
  }
end
