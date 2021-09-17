module SlackStubs
  def slack_url_verification_stub
    {
      token: 'Jhj5dZrVaK7ZwHHjRyZWjbDl',
      challenge: '3eZbrw1aBm2rZgRNFdxV2595E9CY3gmdALWMmHkvFXO7tYXAYM8P',
      type: 'url_verification'
    }
  end

  def slack_message_stub
    {
      token: '[FILTERED]',
      team_id: 'TLST3048H',
      api_app_id: 'A012S5UETV4',
      event: message_event,
      type: 'event_callback',
      event_id: 'Ev013QUX3WV6',
      event_time: 1_588_623_033,
      authed_users: '[FILTERED]',
      webhook: {}
    }
  end

  def slack_attachment_stub
    {
      token: '[FILTERED]',
      team_id: 'TLST3048H',
      api_app_id: 'A012S5UETV4',
      event: message_event,
      type: 'event_callback',
      event_id: 'Ev013QUX3WV6',
      event_time: 1_588_623_033,
      authed_users: '[FILTERED]',
      webhook: {}
    }
  end

  def slack_message_stub_without_thread_ts
    {
      token: '[FILTERED]',
      team_id: '',
      api_app_id: '',
      event: {
        type: 'message',
        client_msg_id: 'ffc6e64e-6f0c-4a3d-b594-faa6b44e48ab',
        text: 'this is test',
        user: 'ULYPAKE5S',
        ts: '1588623033.006000',
        team: 'TLST3048H'
      },
      type: 'event_callback',
      event_id: '',
      event_time: 1_588_623_033,
      authed_users: '[FILTERED]',
      webhook: {}
    }
  end

  def message_event
    {

      client_msg_id: 'ffc6e64e-6f0c-4a3d-b594-faa6b44e48ab',
      type: 'message',
      text: 'this is test <https://chatwoot.com> Hey <@U019KT237LP|Sojan> Test again',
      user: 'ULYPAKE5S',
      ts: '1588623033.006000',
      team: 'TLST3048H',
      blocks: message_blocks,
      files: file_stub,
      thread_ts: '1588623023.005900',
      channel: 'G01354F6A6Q',
      event_ts: '1588623033.006000',
      channel_type: 'group'
    }
  end

  def file_stub
    [
      {
        mimetype: 'image/png',
        url_private: 'https://via.placeholder.com/250x250.png',
        name: 'name_of_the_file',
        title: 'title_of_the_file',
        filetype: 'png',
        url_private_download: 'https://via.placeholder.com/250x250.png'
      }
    ]
  end

  def message_blocks
    [
      {
        type: 'rich_text',
        block_id: 'jaIv3',
        elements: [
          {
            type: 'rich_text_section',
            elements: [
              {
                type: 'text',
                text: 'this is test'
              }
            ]
          }
        ]
      }
    ]
  end
end
