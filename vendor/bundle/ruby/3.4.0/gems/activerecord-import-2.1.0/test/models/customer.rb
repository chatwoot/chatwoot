# frozen_string_literal: true

class Customer < ActiveRecord::Base
  unless ENV["SKIP_COMPOSITE_PK"]
    if ENV['AR_VERSION'].to_f <= 7.0 || ENV['AR_VERSION'].to_f >= 8.0
      has_many :orders,
               inverse_of: :customer,
               primary_key: %i(account_id id),
               foreign_key: %i(account_id customer_id)
    else
      has_many :orders,
               inverse_of: :customer,
               primary_key: %i(account_id id),
               query_constraints: %i(account_id customer_id)
    end

  end
end
