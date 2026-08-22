# == Schema Information
#
# Table name: captain_simple_replies
#
#  id         :bigint           not null, primary key
#  enabled    :boolean          default(TRUE), not null
#  keywords   :jsonb
#  match_type :integer          default("contains"), not null
#  name       :string           not null
#  reply      :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  assistant_id :bigint         not null
#
# Indexes
#
#  index_captain_simple_replies_on_account_id            (account_id)
#  index_captain_simple_replies_on_assistant_id          (assistant_id)
#  index_captain_simple_replies_on_assistant_id_and_enabled (assistant_id,enabled)
#
class Captain::SimpleReply < ApplicationRecord
  KEYWORD_MAX_LENGTH = 100
  MAX_KEYWORDS_PER_REPLY = 20

  enum :match_type, { contains: 0, exact: 1 }

  self.table_name = 'captain_simple_replies'

  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :account

  validates :name, presence: true
  validates :reply, presence: true
  validates :match_type, presence: true
  validate :validate_keywords

  scope :enabled, -> { where(enabled: true) }

  # Keyword matching is intentionally non-LLM: it is the first layer of the
  # assistant pipeline and must stay deterministic and cheap.
  def matches?(message_content)
    normalized_content = normalize(message_content)
    return false if normalized_content.blank?

    keywords.any? { |keyword| keyword_matches?(normalized_content, keyword) }
  end

  private

  def keyword_matches?(normalized_content, keyword)
    normalized_keyword = normalize(keyword)
    return false if normalized_keyword.blank?

    case match_type
    when 'exact' then normalized_content == normalized_keyword
    else starts_at_word_boundary?(normalized_content, normalized_keyword)
    end
  end

  # "order" matches "how do i order?" but not "border". Anchoring only at the
  # start keeps keywords with trailing punctuation (e.g. "refund?") usable.
  def starts_at_word_boundary?(normalized_content, normalized_keyword)
    normalized_content.match?(/\b#{Regexp.escape(normalized_keyword)}/)
  end

  def normalize(text)
    text.to_s.strip.downcase
  end

  def validate_keywords
    errors.add(:keywords, :blank) if keywords.blank?
    return if keywords.blank?

    errors.add(:keywords, :too_long, count: MAX_KEYWORDS_PER_REPLY) if keywords.size > MAX_KEYWORDS_PER_REPLY
    errors.add(:keywords, :invalid) if keywords.any? { |keyword| keyword.to_s.strip.blank? || keyword.to_s.length > KEYWORD_MAX_LENGTH }
  end
end
