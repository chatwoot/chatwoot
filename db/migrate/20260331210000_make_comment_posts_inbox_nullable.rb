# frozen_string_literal: true

class MakeCommentPostsInboxNullable < ActiveRecord::Migration[7.1]
  def change
    # Make inbox_id nullable so comment_posts survive inbox deletion.
    # Posts belong to an account; the inbox is resolved dynamically
    # when needed (e.g. for Graph API calls using the page access token).
    change_column_null :comment_posts, :inbox_id, true

    # Remove the existing strict FK and re-add with ON DELETE SET NULL
    remove_foreign_key :comment_posts, :inboxes
    add_foreign_key :comment_posts, :inboxes, on_delete: :nullify
  end
end
