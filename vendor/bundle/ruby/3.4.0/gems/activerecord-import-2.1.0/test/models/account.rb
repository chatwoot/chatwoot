# frozen_string_literal: true

class Account < ActiveRecord::Base
  self.locking_column = :lock
end
