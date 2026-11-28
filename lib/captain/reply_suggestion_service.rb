class Captain::ReplySuggestionService < Captain::BaseTaskService
  AGENT_REPLY_FEATURE = 'captain_agent_reply_draft'.freeze
  # About 12,500 tokens, a few times the size of an average transcript, so a typical saved reply library fits whole.
  CANNED_RESPONSES_CHARACTER_LIMIT = 50_000
  CANNED_RESPONSES_BATCH_SIZE = 50

  pattr_initialize [:account!, :conversation_display_id!, :user!]

  def perform
    response = make_api_call(
      feature: 'editor',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: formatted_conversation }
      ],
      schema: (Captain::AgentReplySchema if agent_reply_draft?)
    )
    return response unless agent_reply_draft? && response[:message].present?

    finalize_agent_draft(response)
  end

  private

  def agent_reply_draft?
    return @agent_reply_draft if defined?(@agent_reply_draft)

    @agent_reply_draft = account.feature_enabled?(AGENT_REPLY_FEATURE)
  end

  def system_prompt
    template = prompt_from_file(agent_reply_draft? ? 'agent_reply' : 'reply')
    render_liquid_template(template, prompt_variables)
  end

  def prompt_variables
    variables = {
      'channel_type' => conversation.inbox.channel_type,
      'agent_name' => user.name,
      'agent_signature' => user.message_signature.presence
    }
    return variables unless agent_reply_draft?

    variables.merge('business_name' => account.name, 'saved_replies' => saved_replies)
  end

  def render_liquid_template(template_content, variables = {})
    Liquid::Template.parse(template_content).render(variables)
  end

  def formatted_conversation
    transcript = LlmFormatter::ConversationLlmFormatter.new(conversation).format(token_limit: TOKEN_LIMIT, include_timestamps: agent_reply_draft?)
    agent_reply_draft? ? "<conversation>\n#{transcript}\n</conversation>" : transcript
  end

  # Newest edits first, whole responses only, until the character limit. Read in batches so a large library is not
  # loaded whole when only the newest responses fit.
  def saved_replies
    entries = []
    character_count = 0

    canned_response_batches.each do |batch|
      batch.each do |short_code, content|
        entry = "- #{short_code}: #{content}"
        return finish_saved_replies(entries, cut: true) if character_count + entry.length > CANNED_RESPONSES_CHARACTER_LIMIT

        entries << entry
        character_count += entry.length
      end
    end

    finish_saved_replies(entries, cut: false)
  end

  def canned_response_batches
    Enumerator.new do |batches|
      scope = account.canned_responses.order(updated_at: :desc, id: :desc).limit(CANNED_RESPONSES_BATCH_SIZE)
      offset = 0
      loop do
        batch = scope.offset(offset).pluck(:short_code, :content)
        batches << batch
        break if batch.size < CANNED_RESPONSES_BATCH_SIZE

        offset += CANNED_RESPONSES_BATCH_SIZE
      end
    end
  end

  def finish_saved_replies(entries, cut:)
    log_saved_replies_cut(entries.size) if cut
    entries.join("\n").presence
  end

  def log_saved_replies_cut(included_count)
    total_count = account.canned_responses.count
    Rails.logger.info(
      "[CAPTAIN][ReplySuggestion] Account #{account.id}: #{included_count} of #{total_count} canned responses fit in " \
      "#{CANNED_RESPONSES_CHARACTER_LIMIT} characters, the rest were left out"
    )
  end

  # The agent sees only the reply. The note stays in the trace unless no reply is needed, when it tells the agent why.
  def finalize_agent_draft(response)
    answer = response[:message]
    reply = answer['reply'].to_s.strip
    return { message: nil, no_reply_reason: answer['note_for_agent'].to_s.strip } if answer['reply_needed'] == false || reply.blank?

    response[:follow_up_context][:last_response] = reply if response[:follow_up_context]
    response.merge(message: reply)
  end

  def instrumentation_metadata
    return super unless agent_reply_draft?

    super.merge(prompt: 'agent_reply')
  end

  def event_name
    'reply_suggestion'
  end

  def use_account_openai_hook?
    true
  end
end

Captain::ReplySuggestionService.prepend_mod_with('Captain::ReplySuggestionService')
