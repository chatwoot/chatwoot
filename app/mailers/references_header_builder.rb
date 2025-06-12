# Builds RFC 5322 compliant References headers for email threading
#
# This module provides functionality to construct proper References headers
# that maintain email conversation threading according to RFC 5322 standards.
module ReferencesHeaderBuilder
  # Builds a complete References header for an email reply
  #
  # According to RFC 5322, the References header should contain:
  # - All message IDs from the conversation thread in chronological order
  # - The In-Reply-To message ID as the final element
  # - Proper line folding if the header exceeds 998 characters
  #
  # @param conversation [Conversation] The conversation containing the message thread
  # @param in_reply_to_message_id [String] The message ID being replied to
  # @return [String] A properly formatted and folded References header value
  def build_references_header(conversation, in_reply_to_message_id)
    references = collect_chronological_message_ids(conversation)
    references << in_reply_to_message_id

    references = references.compact.uniq
    fold_references_header(references)
  end

  private

  # Collects all message IDs from a conversation in chronological order
  #
  # All email messages (both incoming and outgoing) have source_id populated:
  # - Incoming emails: source_id = original email's Message-ID header
  # - Outgoing emails: source_id = sent email's Message-ID header (set after delivery)
  #
  # @param conversation [Conversation] The conversation to extract message IDs from
  # @return [Array<String>] Array of properly formatted message IDs with angle brackets
  def collect_chronological_message_ids(conversation)
    conversation.messages.where.not(source_id: nil).order(:created_at).pluck(:source_id).map do |source_id|
      source_id.start_with?('<') ? source_id : "<#{source_id}>"
    end
  end

  # Folds References header to comply with RFC 5322 line folding requirements
  #
  # RFC 5322 requires that continuation lines in folded headers start with
  # whitespace (space or tab). This method joins message IDs with CRLF + space,
  # ensuring the first line has no leading space and all continuation lines
  # start with a space as required by the RFC.
  #
  # @param references_array [Array<String>] Array of message IDs to be folded
  # @return [String] A properly folded header value with CRLF line endings
  def fold_references_header(references_array)
    references_array.join("\r\n ")
  end
end