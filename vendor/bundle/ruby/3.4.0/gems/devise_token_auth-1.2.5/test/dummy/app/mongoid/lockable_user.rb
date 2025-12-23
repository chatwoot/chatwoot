# frozen_string_literal: true

class LockableUser
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Locker

  field :locker_locked_at, type: Time
  field :locker_locked_until, type: Time

  locker locked_at_field: :locker_locked_at,
         locked_until_field: :locker_locked_until

  ## User Info
  field :name,      type: String
  field :nickname,  type: String
  field :image,     type: String

  ## Database authenticatable
  field :email,              type: String, default: ''
  field :encrypted_password, type: String, default: ''

  ## Lockable
  field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  field :locked_at,       type: Time

  ## Required
  field :provider, type: String
  field :uid,      type: String, default: ''

  ## Tokens
  field :tokens, type: Hash, default: {}

  # Include default devise modules.
  devise :database_authenticatable, :registerable, :lockable
  include DeviseTokenAuth::Concerns::User
end
