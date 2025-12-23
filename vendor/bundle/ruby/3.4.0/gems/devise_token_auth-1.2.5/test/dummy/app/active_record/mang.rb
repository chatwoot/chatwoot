# frozen_string_literal: true

class Mang < ActiveRecord::Base
  include DeviseTokenAuth::Concerns::User
end
