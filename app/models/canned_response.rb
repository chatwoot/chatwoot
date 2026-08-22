# == Schema Information
#
# Table name: canned_responses
#
#  id               :integer          not null, primary key
#  approval_status  :integer          default("pending"), not null
#  category         :string
#  content          :text
#  reviewed_at      :datetime
#  short_code       :string
#  visibility       :integer          default("personal"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :integer          not null
#  created_by_id    :bigint
#  reviewed_by_id   :bigint
#

class CannedResponse < ApplicationRecord
  include AccountCacheRevalidator

  validates :content, presence: true
  validates :short_code, presence: true
  validates :account, presence: true
  validates :short_code, uniqueness: { scope: :account_id }

  belongs_to :account
  belongs_to :created_by,
             class_name: :User, optional: true, inverse_of: :canned_responses
  belongs_to :reviewed_by,
             class_name: :User, optional: true

  enum visibility: { personal: 0, global: 1 }
  enum approval_status: { pending: 0, approved: 1, rejected: 2 }

  def set_visibility(user, params)
    self.visibility = params[:visibility] if params[:visibility].present?
    self.visibility = :personal if user.agent?
  end

  def apply_create_rules(user)
    set_visibility(user, { visibility: visibility })
    if user.agent?
      self.visibility = :personal
      self.approval_status = :pending
    else
      self.approval_status = :approved
      self.reviewed_by = user
      self.reviewed_at = Time.current
    end
  end

  def apply_update_rules(user)
    set_visibility(user, { visibility: visibility })
    return unless user.agent?

    self.visibility = :personal
    # Agent edits require re-approval before the response is usable again.
    self.approval_status = :pending
    self.reviewed_by = nil
    self.reviewed_at = nil
  end

  def approve!(admin, visibility:)
    self.visibility = visibility
    self.approval_status = :approved
    self.reviewed_by = admin
    self.reviewed_at = Time.current
    save!
  end

  def reject!(admin)
    self.approval_status = :rejected
    self.reviewed_by = admin
    self.reviewed_at = Time.current
    save!
  end

  # Usable in reply picker / slash command.
  def self.usable_for(user)
    scope = Current.account.canned_responses.approved
    scope.global.or(scope.personal.where(created_by_id: user.id))
  end

  # Settings list: agents see own (any status) + approved globals; admins see all.
  def self.manageable_for(user)
    if user.administrator?
      Current.account.canned_responses
    else
      own = Current.account.canned_responses.where(created_by_id: user.id)
      globals = Current.account.canned_responses.global.approved
      own.or(globals)
    end
  end

  def self.with_visibility(user, params)
    records = if ActiveModel::Type::Boolean.new.cast(params[:usable])
                usable_for(user)
              else
                manageable_for(user)
              end

    if params[:approval_status].present? && user.administrator?
      records = records.where(approval_status: params[:approval_status])
    end

    records
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
