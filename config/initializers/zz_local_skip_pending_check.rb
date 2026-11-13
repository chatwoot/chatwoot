Rails.application.config.middleware.delete ActiveRecord::Migration::CheckPending if Rails.env.development?
