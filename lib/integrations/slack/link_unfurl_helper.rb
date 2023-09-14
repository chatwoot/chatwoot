module Integrations::Slack::LinkUnfurlHelper
  def generate_unfurls(url, user_name, email, phone_number, company_name)
    {
      url => {
        'blocks' => user_info_blocks(user_name, email, phone_number, company_name) +
          open_conversation_button(url)
      }
    }
  end

  private

  def user_info_blocks(user_name, email, phone_number, company_name)
    [
      {
        'type' => 'section',
        'fields' => [
          user_info_field('Name', user_name),
          user_info_field('Email', email),
          user_info_field('Phone', phone_number),
          user_info_field('Company', company_name)
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
