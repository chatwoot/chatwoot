class Messages::SearchTextCondition
  pattr_initialize :pattern

  def build
    message_subject = json_value('#>>', message_content_attributes, '{email,subject}')
    conversation_subject = json_value('->>', Conversation.arel_table[:additional_attributes], 'mail_subject')

    messages[:content].matches(pattern)
                      .or(message_subject.matches(pattern))
                      .or(blank(message_subject).and(conversation_subject.matches(pattern)))
                      .or(attachment_transcript_match)
                      .or(call_transcript_match)
  end

  private

  def messages
    Message.arel_table
  end

  def attachment_transcript_match
    attachments = Attachment.arel_table
    Attachment.where(attachments[:message_id].eq(messages[:id]))
              .where(json_value('->>', attachments[:meta], 'transcribed_text').matches(pattern))
              .arel.exists
  end

  def call_transcript_match
    calls = Call.arel_table
    transcript_exists = Call.where(calls[:message_id].eq(messages[:id])).where(calls[:transcript].matches(pattern)).arel.exists
    messages[:content_type].eq(Message.content_types[:voice_call]).and(transcript_exists)
  end

  def message_content_attributes
    as_text = json_value('#>>', messages[:content_attributes], '{}')
    Arel::Nodes::NamedFunction.new('CAST', [as_text.as('jsonb')])
  end

  def json_value(operator, node, path)
    Arel::Nodes::InfixOperation.new(operator, node, Arel::Nodes.build_quoted(path))
  end

  def blank(node)
    trimmed = Arel::Nodes::NamedFunction.new('BTRIM', [node])
    Arel::Nodes::NamedFunction.new('NULLIF', [trimmed, Arel::Nodes.build_quoted('')]).eq(nil)
  end
end
