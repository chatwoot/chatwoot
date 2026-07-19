# == Schema Information
#
# Table name: canned_responses
#
#  id            :integer          not null, primary key
#  category      :string
#  content       :text
#  short_code    :string
#  visibility    :integer          default("personal"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer          not null
#  created_by_id :bigint
#

class CannedResponse < ApplicationRecord
  validates :content, presence: true
  validates :short_code, presence: true
  validates :account, presence: true
  validates :short_code, uniqueness: { scope: :account_id }

  belongs_to :account
  belongs_to :created_by,
             class_name: :User, optional: true, inverse_of: :canned_responses

  enum visibility: { personal: 0, global: 1 }

  def set_visibility(user, params)
    self.visibility = params[:visibility] if params[:visibility].present?
    self.visibility = :personal if user.agent?
  end

  def self.with_visibility(user, _params)
    records = Current.account.canned_responses.global
    records.or(personal.where(created_by_id: user.id, account_id: Current.account.id))
  end

  scope :order_by_search, lambda { |search|
    short_code_starts_with = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 1', "#{search}%"])
    short_code_like = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 0.5', "%#{search}%"])
    category_like = sanitize_sql_array(['WHEN category ILIKE ? THEN 0.3', "%#{search}%"])
    content_like = sanitize_sql_array(['WHEN content ILIKE ? THEN 0.2', "%#{search}%"])

    order_clause = "CASE #{short_code_starts_with} #{short_code_like} #{category_like} #{content_like} ELSE 0 END"

    order(Arel.sql(order_clause) => :desc)
  }
end
