module Seeders::MessageSeeder
  def self.create_sample_email_collect_message(conversation)
    Message.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      conversation: conversation,
      message_type: :template,
      content_type: :input_email,
      content: 'Want us to email you a copy of your quote?'
    )
  end

  def self.create_sample_csat_collect_message(conversation)
    Message.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      conversation: conversation,
      message_type: :template,
      content_type: :input_csat,
      content: 'How would you rate your experience with Paperlayer today?'
    )
  end

  def self.create_sample_cards_message(conversation)
    Message.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      conversation: conversation,
      message_type: :template,
      content_type: 'cards',
      content: 'cards',
      content_attributes: {
        items: [
          sample_card_item,
          sample_card_item
        ]
      }
    )
  end

  def self.sample_card_item
    {
      media_url: 'https://i.imgur.com/d8Djr4k.jpg',
      title: 'Premium Copy Paper - 20lb',
      description: 'Bright white, 500 sheets per ream. Perfect for everyday printing.',
      actions: [
        {
          type: 'link',
          text: 'View Details',
          uri: 'http://paperlayer.com/products/copy-paper'
        },
        {
          type: 'postback',
          text: 'Request Quote',
          payload: 'QUOTE_REQUESTED'
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
      content: 'What type of paper are you interested in?',
      content_type: 'input_select',
      content_attributes: {
        items: [
          { title: '📄 Copy Paper (20lb)', value: 'copy-paper-20' },
          { title: '📋 Cardstock (110lb)', value: 'cardstock-110' },
          { title: '🎨 Colored Paper', value: 'colored-paper' },
          { title: '✨ Premium (32lb)', value: 'premium-32' }
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
      content: 'form',
      content_attributes: sample_form
    )
  end

  def self.sample_form
    {
      items: [
        { name: 'company', placeholder: 'Your company name', type: 'text', label: 'Company Name', required: 'required',
          pattern_error: 'Please enter your company name' },
        { name: 'email', placeholder: 'your.email@company.com', type: 'email', label: 'Email Address', required: 'required',
          pattern_error: 'Please enter a valid email', pattern: '^[^\s@]+@[^\s@]+\.[^\s@]+$' },
        { name: 'quantity', placeholder: 'e.g., 50 cases', type: 'text', label: 'Quantity Needed', required: 'required',
          pattern_error: 'Please specify quantity' },
        { name: 'paper_type', label: 'Paper Type', type: 'select', options: [
          { label: '📄 Copy Paper (20lb)', value: 'copy-20' },
          { label: '📋 Cardstock (110lb)', value: 'cardstock-110' },
          { label: '🎨 Colored Paper', value: 'colored' },
          { label: '✨ Premium (32lb)', value: 'premium-32' }
        ] },
        { name: 'requirements', placeholder: 'Any special requirements or delivery instructions', type: 'text_area',
          label: 'Additional Notes', pattern_error: 'Please fill this field' }
      ]
    }
  end

  def self.create_sample_articles_message(conversation)
    Message.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      conversation: conversation,
      message_type: :template,
      content: 'Helpful Resources',
      content_type: 'article',
      content_attributes: {
        items: [
          { title: 'Paper Weight Guide', description: 'Understanding paper weights and their best uses',
            link: 'http://paperlayer.com/help/paper-weights' },
          { title: 'Bulk Order Discounts', description: 'Learn about our volume pricing tiers', link: 'http://paperlayer.com/help/bulk-pricing' },
          { title: 'Custom Printing Options', description: 'Letterhead, envelopes, and branded materials', link: 'http://paperlayer.com/help/custom-printing' }
        ]
      }
    )
  end
end
