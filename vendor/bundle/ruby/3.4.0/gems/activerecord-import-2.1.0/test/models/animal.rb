# frozen_string_literal: true

class Animal < ActiveRecord::Base
  after_initialize :validate_name_presence, if: :new_record?
  def validate_name_presence
    raise ArgumentError if name.nil?
  end
end
