# frozen_string_literal: true

class CreateCommentPosts < ActiveRecord::Migration[7.1]
  def change
    create_table :comment_posts do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :inbox, null: false, foreign_key: true, index: true

      t.string :platform, null: false              # 'facebook' or 'instagram'
      t.string :post_id, null: false                # Graph API post ID
      t.string :page_id                             # Page/IG Business Account ID

      # Cached post metadata (fetched from Graph API)
      t.text :post_text
      t.string :post_media_url
      t.string :post_media_type                     # 'image', 'video', 'carousel', 'text'
      t.string :post_permalink
      t.datetime :post_created_at

      # Aggregates
      t.integer :conversations_count, default: 0, null: false
      t.datetime :last_comment_at

      t.timestamps
    end

    add_index :comment_posts, %i[account_id post_id], unique: true
    add_index :comment_posts, %i[account_id inbox_id last_comment_at], name: 'idx_comment_posts_last_comment'
    add_index :comment_posts, %i[account_id inbox_id post_created_at], name: 'idx_comment_posts_post_date'
  end
end
