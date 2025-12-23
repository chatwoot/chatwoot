# frozen_string_literal: true

class LockableUser < ActiveRecord::Base
  # Include default devise modules.
  devise :database_authenticatable, :registerable, :lockable
  include DeviseTokenAuth::Concerns::User
end
