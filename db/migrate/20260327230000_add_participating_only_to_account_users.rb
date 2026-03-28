# frozen_string_literal: true

# Migration to add participating_only flag to account_users
# This enables restricting agents to only see conversations they are assigned to or participated in
class AddParticipatingOnlyToAccountUsers < ActiveRecord::Migration[7.0]
  def change
    # Add participating_only boolean flag with default false
    # When true: agent can only see conversations where they are assignee or have sent messages
    # When false: agent can see all conversations in their assigned inboxes (default behavior)
    add_column :account_users, :participating_only, :boolean, default: false, null: false

    # Add index for performance when filtering by this flag
    add_index :account_users, :participating_only
  end
end
