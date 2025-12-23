# frozen_string_literal: true

class Vendor < ActiveRecord::Base
  store :preferences, accessors: [:color], coder: JSON

  store_accessor :data, :size
  store_accessor :config, :contact
  store_accessor :settings, :charge_code
end
