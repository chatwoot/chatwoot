# frozen_string_literal: true

# == Schema Information
#
# Table name: embed_tokens
#
#  id           :bigint           not null, primary key
#  jti          :string           not null
#  token_digest :string           not null
#  user_id      :bigint           not null
#  account_id   :bigint           not null
#  inbox_id     :bigint
#  created_by_id :bigint
#  revoked_at   :datetime
#  last_used_at :datetime
#  usage_count  :integer          default(0), not null
#  note         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_embed_tokens_on_jti           (jti) UNIQUE
#  index_embed_tokens_on_token_digest  (token_digest) UNIQUE
#  index_embed_tokens_on_user_id_and_account_id (user_id, account_id)
#  index_embed_tokens_on_revoked_at    (revoked_at)
#

class EmbedToken < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :inbox, optional: true
  belongs_to :created_by, class_name: 'User', optional: true

  validates :jti, presence: true, uniqueness: true
  validates :token_digest, presence: true, uniqueness: true

  scope :active, -> { where(revoked_at: nil) }
  scope :revoked, -> { where.not(revoked_at: nil) }

  def active?
    revoked_at.nil?
  end

  def revoked?
    !active?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def mark_used!
    update!(
      last_used_at: Time.current,
      usage_count: usage_count + 1
    )
  end
end

