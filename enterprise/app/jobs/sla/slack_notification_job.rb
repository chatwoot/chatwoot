class Sla::SlackNotificationJob < ApplicationJob
  queue_as :default

  def perform(conversation, account, message)
    @conversation = conversation
    @account = account
    @message = message

    slack_integration = @account.integrations.find_by(name: 'slack')
    return unless slack_integration&.active?

    send_slack_notification(slack_integration)
  end

  private

  def send_slack_notification(slack_integration)
    slack_client = Slack::Web::Client.new(token: slack_integration.access_token)
    
    # Determine the channel - try conversation channel first, then default
    channel = determine_slack_channel(slack_integration)
    
    slack_client.chat_postMessage(
      channel: channel,
      text: @message,
      blocks: slack_message_blocks,
      username: 'Chatwoot SLA Alert',
      icon_emoji: ':warning:'
    )
  rescue => e
    Rails.logger.error "Failed to send Slack SLA notification: #{e.message}"
  end

  def determine_slack_channel(slack_integration)
    # Try to get queue-specific or department-specific channel
    if @conversation.queue&.routing_rules.present?
      slack_channel = @conversation.queue.routing_rules['slack_channel']
      return slack_channel if slack_channel.present?
    end

    # Fall back to default channel from integration settings
    slack_integration.settings.dig('default_channel') || '#general'
  end

  def slack_message_blocks
    [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '🚨 SLA Breach Alert'
        }
      },
      {
        type: 'section',
        fields: [
          {
            type: 'mrkdwn',
            text: "*Conversation:* ##{@conversation.display_id}"
          },
          {
            type: 'mrkdwn',
            text: "*Contact:* #{@conversation.contact.name}"
          },
          {
            type: 'mrkdwn',
            text: "*Assigned:* #{@conversation.assignee&.name || 'Unassigned'}"
          },
          {
            type: 'mrkdwn',
            text: "*Queue:* #{@conversation.queue&.name || 'None'}"
          },
          {
            type: 'mrkdwn',
            text: "*Department:* #{@conversation.queue&.department&.name || 'None'}"
          },
          {
            type: 'mrkdwn',
            text: "*SLA Policy:* #{@conversation.sla_policy&.name || 'None'}"
          }
        ]
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: @message
        }
      },
      {
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: {
              type: 'plain_text',
              text: 'View Conversation'
            },
            url: conversation_url,
            style: 'primary'
          }
        ]
      }
    ]
  end

  def conversation_url
    Rails.application.routes.url_helpers.app_account_conversation_url(
      @conversation.account.id, 
      @conversation.display_id,
      host: ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    )
  end
end