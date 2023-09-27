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
          preview_field('Name', user_info[:user_name]),
          preview_field('Email', user_info[:email]),
          preview_field('Phone', user_info[:phone_number]),
          preview_field('Company', user_info[:company_name]),
          preview_field('Inbox', inbox_name),
          preview_field('Inbox Type', inbox_type)
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
              'text' => 'Open conversation',
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
