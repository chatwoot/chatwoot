class Integrations::Slack::LinkUnfurlFormatter
  pattr_initialize [:url!, :user_info!]

  def perform
    return {} if url.blank?

    {
      url => {
        'blocks' => user_info_blocks(user_info) +
          open_conversation_button(url)
      }
    }
  end

  private

  def user_info_blocks(user_info)
    [
      {
        'type' => 'section',
        'fields' => [
          user_info_field('Name', user_info[:user_name]),
          user_info_field('Email', user_info[:email]),
          user_info_field('Phone', user_info[:phone_number]),
          user_info_field('Company', user_info[:company_name])
        ]
      }
    ]
  end

  def user_info_field(label, value)
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
