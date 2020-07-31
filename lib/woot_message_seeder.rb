module WootMessageSeeder
  def self.create_sample_email_collect_message(conversation)
    Message.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      conversation: conversation,
      message_type: :template,
      content_type: :input_email,
      content: 'Get notified by email'
    )
  end

  def self.create_sample_cards_message(conversation)
    Message.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      conversation: conversation,
      message_type: :template,
      content_type: 'cards',
      content_attributes: {
        items: [
          sample_card_item
        ]
      }
    )
  end

  def self.sample_card_item
    {
      "media_url": 'https://assets.ajio.com/medias/sys_master/root/hdb/h9a/13582024212510/-1117Wx1400H-460345219-white-MODEL.jpg',
      "title": 'Nike Shoes 2.0',
      "description": 'Running with Nike Shoe 2.0',
      "actions": [
        {
          "type": 'link',
          "text": 'View More',
          "uri": 'google.com'
        },
        {
          "type": 'postback',
          "text": 'Add to cart',
          "payload": 'ITEM_SELECTED'
        }
      ]
    }
  end

  def self.create_sample_input_select_message(conversation)
    Message.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      conversation: conversation,
      message_type: :template,
      content: 'Your favorite food',
      content_type: 'input_select',
      content_attributes: {
        "items": [
          { "title": '🌯 Burito', "value": 'Burito' },
          { "title": '🍝 Pasta', "value": 'Pasta' },
          { "title": ' 🍱 Sushi', "value": 'Sushi' },
          { "title": ' 🥗 Salad', "value": 'Salad' }
        ]
      }
    )
  end

  def self.create_sample_form_message(conversation)
    Message.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      conversation: conversation,
      message_type: :template,
      content_type: 'form',
      content_attributes: {
        "items": [
          { "name": 'email', "placeholder": 'Please enter your email', "type": 'email', "label": 'Email' },
          { "name": 'text_aread', "placeholder": 'Please enter text', "type": 'text_area', "label": 'Large Text' },
          { "name": 'text', "placeholder": 'Please enter text', "type": 'text', "label": 'text', "default": 'defaut value' }
        ]
      }
    )
  end

  def self.create_sample_articles_message(conversation)
    Message.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      conversation: conversation,
      message_type: :template,
      content: 'Tech Companies',
      content_type: 'article',
      content_attributes: {
        "items": [
          { "title": 'Apple', "description": 'Hardware reimagined', "link": 'http://apple.com' },
          { "title": 'Google', "description": 'The best Search Engine', "link": 'http://google.com' }
        ]
      }
    )
  end
end
