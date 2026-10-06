class ConversationMonitors::SlackAlertService
  MESSAGE_EXCERPT_LENGTH = 300
  DEFAULT_EMOJI = '🔔'.freeze

  pattr_initialize [:monitor!, :conversation!, :hook!]

  def perform
    post_alert
  rescue Slack::Web::Api::Errors::NotInChannel
    # The bot can add itself to public channels; private ones need an invite.
    slack_client.conversations_join(channel: monitor.slack_channel_id)
    post_alert
  end

  private

  def post_alert
    slack_client.chat_postMessage(
      channel: monitor.slack_channel_id, text: t('title', name: monitor.name), blocks: blocks, unfurl_links: false
    )
  end

  def blocks
    [
      { type: 'header', text: { type: 'plain_text', text: "#{emoji} #{monitor.name}", emoji: true } },
      context(t('matched', time: matched_time)),
      { type: 'section', text: mrkdwn(summary) },
      { type: 'section', fields: fields },
      { type: 'divider' },
      context("*#{t('condition')}:* #{escape(monitor.condition)}")
    ]
  end

  # Monitor icons are either an emoji or the name of a dashboard icon.
  def emoji
    monitor.icon.to_s.match?(/\A[a-z]/) ? DEFAULT_EMOJI : monitor.icon.presence || DEFAULT_EMOJI
  end

  def summary
    link = "*<#{conversation_url}|#{t('conversation', id: conversation.display_id)}>*"
    [t('summary', conversation: link, contact: escape(conversation.contact.name)), latest_message_quote].compact.join("\n")
  end

  def latest_message_quote
    content = conversation.messages.incoming.where(private: false).where.not(content: [nil, '']).order(:created_at).last&.content
    escape(content.truncate(MESSAGE_EXCERPT_LENGTH)).gsub(/^/, '> ') if content.present?
  end

  def fields
    [
      field('inbox', conversation.inbox.name),
      field('assignee', conversation.assignee&.name || t('unassigned')),
      field('status', conversation.status.humanize),
      field('confidence', confidence)
    ]
  end

  def evaluation
    @evaluation ||= monitor.evaluations.find_by(conversation_id: conversation.id)
  end

  def confidence
    evaluation&.score ? "#{(evaluation.score * 100).round}%" : t('unknown')
  end

  # Slack renders this in each reader's own timezone.
  def matched_time
    time = evaluation&.matched_at || Time.current
    "<!date^#{time.to_i}^{date_short_pretty} at {time}|#{time.utc.to_fs(:long)} UTC>"
  end

  def conversation_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{conversation.account_id}/conversations/#{conversation.display_id}"
  end

  def field(key, value)
    mrkdwn("*#{t(key)}*\n#{escape(value)}")
  end

  def context(text)
    { type: 'context', elements: [mrkdwn(text)] }
  end

  def mrkdwn(text)
    { type: 'mrkdwn', text: text }
  end

  # Slack treats &, < and > as control characters in mrkdwn.
  def escape(text)
    text.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
  end

  def t(key, **)
    I18n.t("conversation_monitors.slack_alert.#{key}", **)
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: hook.access_token)
  end
end
