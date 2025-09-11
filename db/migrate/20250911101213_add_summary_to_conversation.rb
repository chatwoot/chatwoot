# frozen_string_literal: true

class AddSummaryToConversation < ActiveRecord::Migration[7.1] # :nodoc:
  def change
    add_column :conversations, :summary, :text, default: ''
  end
end
