# frozen_string_literal: true

# == Schema Information
#
# Table name: comment_posts
#
#  id                  :bigint           not null, primary key
#  conversations_count :integer          default(0), not null
#  last_comment_at     :datetime
#  platform            :string           not null
#  post_created_at     :datetime
#  post_media_type     :string
#  post_media_url      :string
#  post_permalink      :string
#  post_text           :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  inbox_id            :bigint
#  page_id             :string
#  post_id             :string           not null
#
# Indexes
#
#  idx_comment_posts_last_comment                 (account_id,inbox_id,last_comment_at)
#  idx_comment_posts_post_date                    (account_id,inbox_id,post_created_at)
#  index_comment_posts_on_account_id              (account_id)
#  index_comment_posts_on_account_id_and_post_id  (account_id,post_id) UNIQUE
#  index_comment_posts_on_inbox_id                (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (inbox_id => inboxes.id) ON DELETE => nullify
#
class CommentPost < ApplicationRecord
  belongs_to :account
  belongs_to :inbox, optional: true

  validates :post_id, presence: true, uniqueness: { scope: :account_id }
  validates :platform, presence: true, inclusion: { in: %w[facebook instagram] }

  scope :ordered_by_latest_comment, -> { order(last_comment_at: :desc) }
  scope :ordered_by_post_date, -> { order(post_created_at: :desc) }
  scope :for_platform, ->(platform) { where(platform: platform) if platform.present? }
  scope :for_inbox, ->(inbox_id) { where(inbox_id: inbox_id) if inbox_id.present? }

  # Dynamically resolve the current inbox for this platform (handles inbox deletion/re-creation)
  def resolved_inbox
    return inbox if inbox.present?

    resolved = if platform == 'instagram'
                 account.inboxes.where(channel_type: 'Channel::Instagram').first
               else
                 account.inboxes.where(channel_type: 'Channel::FacebookPage').first
               end

    # Re-link if found
    update_column(:inbox_id, resolved.id) if resolved
    resolved
  end

  # Find conversations that belong to this post via additional_attributes.post_id
  def conversations
    account.conversations.where("additional_attributes->>'post_id' = ?", post_id)
  end

  # Recompute aggregate counters from actual conversations
  def recount!
    convs = conversations
    update!(
      conversations_count: convs.count,
      last_comment_at: convs.maximum(:created_at) || created_at
    )
  end
end
