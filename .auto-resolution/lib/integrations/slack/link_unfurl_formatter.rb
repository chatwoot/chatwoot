class Integrations::Slack::LinkUnfurlFormatter
  pattr_initialize [:url!, :user_info!, :inbox_name!, :inbox_type!]

  def perform
    return {} if url.blank?

    {
      url => {
        'blocks' => preivew_blocks(user_info) +
          open_conversation_button(url)
      }
    }
  end

  private

  def preivew_blocks(user_info)
    [
      {
        'type' => 'section',
        'fields' => [
          preview_field(I18n.t('slack_unfurl.fields.name'), user_info[:user_name]),
          preview_field(I18n.t('slack_unfurl.fields.email'), user_info[:email]),
          preview_field(I18n.t('slack_unfurl.fields.phone_number'), user_info[:phone_number]),
          preview_field(I18n.t('slack_unfurl.fields.company_name'), user_info[:company_name]),
          preview_field(I18n.t('slack_unfurl.fields.inbox_name'), inbox_name),
          preview_field(I18n.t('slack_unfurl.fields.inbox_type'), inbox_type)
        ]
      }
    ]
  end

  def preview_field(label, value)
    {
      'type' => 'mrkdwn',
      'text' => "*#{label}:*\n#{value}"
    }
  end

  def open_conversation_button(url)
    [
      {
        'type' => 'actions',
        'elements' => [
          {
            'type' => 'button',
            'text' => {
              'type' => 'plain_text',
              'text' => I18n.t('slack_unfurl.button'),
              'emoji' => true
            },
            'url' => url,
            'action_id' => 'button-action'
          }
        ]
      }
    ]
  end
end
