# == Schema Information
#
# Table name: canned_responses
#
#  id            :integer          not null, primary key
#  content       :text
#  short_code    :string
#  visibility    :integer          default("public_response"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer          not null
#  created_by_id :integer
#
# Indexes
#
#  index_canned_responses_on_created_by_id  (created_by_id)
#  index_canned_responses_on_visibility     (visibility)
#

class CannedResponse < ApplicationRecord
  include AccountCacheRevalidator

  enum visibility: { public_response: 0, private_response: 1 }

  belongs_to :account
  belongs_to :created_by, class_name: 'User', optional: true
  has_many :canned_response_scopes, dependent: :destroy

  validates :content, presence: true
  validates :short_code, presence: true
  validates :account, presence: true

  scope :order_by_search, lambda { |search|
    short_code_starts_with = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 1', "#{search}%"])
    short_code_like = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 0.5', "%#{search}%"])
    content_like = sanitize_sql_array(['WHEN content ILIKE ? THEN 0.2', "%#{search}%"])
    order_clause = "CASE #{short_code_starts_with} #{short_code_like} #{content_like} ELSE 0 END"
    order(Arel.sql(order_clause) => :desc)
  }

  # A private response is visible when one of its scopes lists the user, one of the user's
  # teams, or a matching inbox: the inbox given as `inbox_id` (composer context), otherwise
  # any inbox the user is a member of.
  scope :accessible_to, lambda { |user, inbox_id: nil|
    team_ids = user.team_members.pluck(:team_id)
    inbox_ids = inbox_id.present? ? [inbox_id.to_i] : user.inbox_members.pluck(:inbox_id)

    matching_scopes = CannedResponseScope.where(
      'user_ids @> ARRAY[:user_id]::integer[] OR team_ids && ARRAY[:team_ids]::integer[] OR inbox_ids && ARRAY[:inbox_ids]::integer[]',
      user_id: user.id, team_ids: team_ids.presence || [0], inbox_ids: inbox_ids.presence || [0]
    )

    where(visibility: :public_response)
      .or(where(visibility: :private_response, id: matching_scopes.select(:canned_response_id)))
  }
end
