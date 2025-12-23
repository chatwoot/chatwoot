# frozen_string_literal: true

class Discount < ActiveRecord::Base
  belongs_to :discountable, polymorphic: true
end
