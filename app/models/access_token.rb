# == Schema Information
#
# Table name: access_tokens
#
#  id         :bigint           not null, primary key
#  owner_type :string
#  scope      :string           default("full"), not null
#  token      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  owner_id   :bigint
#
# Indexes
#
#  index_access_tokens_on_owner_and_scope          (owner_type,owner_id,scope) UNIQUE
#  index_access_tokens_on_owner_type_and_owner_id  (owner_type,owner_id)
#  index_access_tokens_on_token                    (token) UNIQUE
#

class AccessToken < ApplicationRecord
  # Schema-wise this table can hold any number of tokens per owner, but we
  # intentionally cap user-facing tokens at two: one `full` and one `read_only`.
  # The User model's has_one associations + auto-create callbacks enforce the
  # 1+1 contract; this validation only constrains the allowed scope values.
  SCOPES = %w[full read_only].freeze

  has_secure_token :token
  belongs_to :owner, polymorphic: true
  validates :scope, inclusion: { in: SCOPES }
end
