# frozen_string_literal: true

class AddScheduleToAutomationRules < ActiveRecord::Migration[7.1]
  def change
    add_column :automation_rules, :schedule, :jsonb, default: {}, null: false
  end
end
