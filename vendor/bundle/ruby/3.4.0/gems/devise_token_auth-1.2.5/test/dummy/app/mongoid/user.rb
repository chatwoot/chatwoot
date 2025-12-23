# frozen_string_literal: true

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Locker

  field :locker_locked_at, type: Time
  field :locker_locked_until, type: Time

  locker locked_at_field: :locker_locked_at,
         locked_until_field: :locker_locked_until

  ## User Info
  field :name,             type: String
  field :nickname,         type: String
  field :image,            type: String
  field :favorite_color,   type: String
  field :operating_thetan, type: Integer

  ## Database authenticatable
  field :email,              type: String, default: ''
  field :encrypted_password, type: String, default: ''

  ## Recoverable
  field :reset_password_token,        type: String
  field :reset_password_sent_at,      type: Time
  field :reset_password_redirect_url, type: String
  field :allow_password_change,       type: Boolean, default: false

  ## Rememberable
  field :remember_created_at, type: Time

  ## Confirmable
  field :confirmation_token,   type: String
  field :confirmed_at,         type: Time
  field :confirmation_sent_at, type: Time
  field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Required
  field :provider, type: String
  field :uid,      type: String, default: ''

  ## Tokens
  field :tokens, type: Hash, default: {}

  include DeviseTokenAuth::Concerns::User
  include FavoriteColor
end
