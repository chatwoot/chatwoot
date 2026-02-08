# loading installation configs
GlobalConfig.clear_cache
ConfigLoader.new.process

## Seeds productions
if Rails.env.production?
  # Setup Onboarding flow
  Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)
end

## Seeds for Local Development
unless Rails.env.production?

  # Enables creating additional accounts from dashboard
  installation_config = InstallationConfig.find_by(name: 'CREATE_NEW_ACCOUNT_FROM_DASHBOARD')
  installation_config.value = true
  installation_config.save!
  GlobalConfig.clear_cache

  account = Account.create!(
    name: 'Paperlayer'
  )

  secondary_account = Account.create!(
    name: 'Acme Org'
  )

  # Create Admin
  user = User.new(name: 'Sarah Johnson', email: 'sarah@paperlayer.com', password: 'Password1!', type: 'SuperAdmin')
  user.skip_confirmation!
  user.save!

  # Create Sales Team
  sales_lead = User.new(name: 'Marcus Chen', email: 'marcus@paperlayer.com', password: 'Password1!')
  sales_lead.skip_confirmation!
  sales_lead.save!

  sales_agent_1 = User.new(name: 'Emily Rodriguez', email: 'emily@paperlayer.com', password: 'Password1!')
  sales_agent_1.skip_confirmation!
  sales_agent_1.save!

  sales_agent_2 = User.new(name: 'David Kim', email: 'david@paperlayer.com', password: 'Password1!')
  sales_agent_2.skip_confirmation!
  sales_agent_2.save!

  # Create Support Team
  support_lead = User.new(name: 'Jennifer Williams', email: 'jennifer@paperlayer.com', password: 'Password1!')
  support_lead.skip_confirmation!
  support_lead.save!

  support_agent_1 = User.new(name: 'Alex Thompson', email: 'alex@paperlayer.com', password: 'Password1!')
  support_agent_1.skip_confirmation!
  support_agent_1.save!

  support_agent_2 = User.new(name: 'Rachel Green', email: 'rachel@paperlayer.com', password: 'Password1!')
  support_agent_2.skip_confirmation!
  support_agent_2.save!

  # Create Operations Team
  operations_lead = User.new(name: 'Tom Anderson', email: 'tom@paperlayer.com', password: 'Password1!')
  operations_lead.skip_confirmation!
  operations_lead.save!

  operations_agent = User.new(name: 'Lisa Martinez', email: 'lisa@paperlayer.com', password: 'Password1!')
  operations_agent.skip_confirmation!
  operations_agent.save!

  # Create Account Users
  AccountUser.create!(account_id: account.id, user_id: user.id, role: :administrator)
  AccountUser.create!(account_id: account.id, user_id: sales_lead.id, role: :administrator)
  AccountUser.create!(account_id: account.id, user_id: sales_agent_1.id, role: :agent)
  AccountUser.create!(account_id: account.id, user_id: sales_agent_2.id, role: :agent)
  AccountUser.create!(account_id: account.id, user_id: support_lead.id, role: :administrator)
  AccountUser.create!(account_id: account.id, user_id: support_agent_1.id, role: :agent)
  AccountUser.create!(account_id: account.id, user_id: support_agent_2.id, role: :agent)
  AccountUser.create!(account_id: account.id, user_id: operations_lead.id, role: :administrator)
  AccountUser.create!(account_id: account.id, user_id: operations_agent.id, role: :agent)
  AccountUser.create!(account_id: secondary_account.id, user_id: user.id, role: :administrator)

  # Create Teams
  sales_team = Team.create!(
    account: account,
    name: 'Sales Team',
    description: 'Handles all sales inquiries, quotes, and bulk orders',
    allow_auto_assign: true
  )

  support_team = Team.create!(
    account: account,
    name: 'Customer Support',
    description: 'Handles customer service, product questions, and order issues',
    allow_auto_assign: true
  )

  operations_team = Team.create!(
    account: account,
    name: 'Operations',
    description: 'Handles shipping, logistics, and order fulfillment',
    allow_auto_assign: true
  )

  # Add members to Sales Team
  TeamMember.create!(team: sales_team, user: sales_lead)
  TeamMember.create!(team: sales_team, user: sales_agent_1)
  TeamMember.create!(team: sales_team, user: sales_agent_2)

  # Add members to Support Team
  TeamMember.create!(team: support_team, user: support_lead)
  TeamMember.create!(team: support_team, user: support_agent_1)
  TeamMember.create!(team: support_team, user: support_agent_2)

  # Add members to Operations Team
  TeamMember.create!(team: operations_team, user: operations_lead)
  TeamMember.create!(team: operations_team, user: operations_agent)

  # Create Inboxes
  web_widget = Channel::WebWidget.create!(account: account, website_url: 'https://paperlayer.com')
  inbox = Inbox.create!(channel: web_widget, account: account, name: 'Website Chat')
  InboxMember.create!(user: user, inbox: inbox)
  InboxMember.create!(user: sales_lead, inbox: inbox)
  InboxMember.create!(user: sales_agent_1, inbox: inbox)
  InboxMember.create!(user: sales_agent_2, inbox: inbox)
  InboxMember.create!(user: support_lead, inbox: inbox)
  InboxMember.create!(user: support_agent_1, inbox: inbox)
  InboxMember.create!(user: support_agent_2, inbox: inbox)
  InboxMember.create!(user: operations_lead, inbox: inbox)
  InboxMember.create!(user: operations_agent, inbox: inbox)

  sales_inbox = Inbox.create!(channel: Channel::WebWidget.create!(account: account, website_url: 'https://paperlayer.com/sales'), account: account,
                              name: 'Sales Inquiries')
  InboxMember.create!(user: user, inbox: sales_inbox)
  InboxMember.create!(user: sales_lead, inbox: sales_inbox)
  InboxMember.create!(user: sales_agent_1, inbox: sales_inbox)
  InboxMember.create!(user: sales_agent_2, inbox: sales_inbox)

  email_channel = Channel::Email.create!(
    account: account,
    email: 'support@paperlayer.com',
    forward_to_email: 'support@paperlayer.com'
  )
  support_inbox = Inbox.create!(channel: email_channel, account: account, name: 'Email Support')
  InboxMember.create!(user: support_lead, inbox: support_inbox)
  InboxMember.create!(user: support_agent_1, inbox: support_inbox)
  InboxMember.create!(user: support_agent_2, inbox: support_inbox)

  # Create Labels
  bulk_order_label = Label.create!(account: account, title: 'bulk-order', description: 'Large volume paper orders', color: '#00C875',
                                   show_on_sidebar: true)
  custom_print_label = Label.create!(account: account, title: 'custom-printing', description: 'Custom letterhead and printing requests',
                                     color: '#784BD1', show_on_sidebar: true)
  urgent_label = Label.create!(account: account, title: 'urgent', description: 'Rush delivery needed', color: '#E2445C', show_on_sidebar: true)
  pricing_label = Label.create!(account: account, title: 'pricing-inquiry', description: 'Quote requests and pricing questions', color: '#FDAB3D',
                                show_on_sidebar: true)
  delivery_label = Label.create!(account: account, title: 'delivery-issue', description: 'Shipping and delivery concerns', color: '#9CD326',
                                 show_on_sidebar: true)
  product_label = Label.create!(account: account, title: 'product-question', description: 'Questions about paper types and products',
                                color: '#579BFC', show_on_sidebar: true)

  # Create Canned Responses
  CannedResponse.create!(account: account, short_code: 'welcome',
                         content: 'Thank you for contacting Paperlayer! We\'re committed to providing the highest quality paper products for your business. How can I help you today?')
  CannedResponse.create!(account: account, short_code: 'bulk',
                         content: 'For bulk orders over 100 reams, we offer competitive wholesale pricing. Let me get you a custom quote. Could you share your estimated monthly paper needs?')
  CannedResponse.create!(account: account, short_code: 'pricing',
                         content: 'Our standard pricing for premium white copy paper (20lb, 8.5x11) is $45 per case (10 reams). We offer volume discounts starting at 50 cases.')
  CannedResponse.create!(account: account, short_code: 'delivery',
                         content: 'We offer same-day delivery for local orders (within 50 miles) placed before noon, and 2-3 business days for standard shipping. Rush delivery is available for an additional fee.')
  CannedResponse.create!(account: account, short_code: 'custom',
                         content: 'We provide custom letterhead printing services with a minimum order of 5 reams. Typical turnaround is 5-7 business days. Would you like to discuss your design requirements?')
  CannedResponse.create!(account: account, short_code: 'stock',
                         content: 'We carry a full range of paper products: copy paper (20lb-32lb), cardstock, colored paper, glossy photo paper, and specialty papers. What type are you interested in?')
  CannedResponse.create!(account: account, short_code: 'closing',
                         content: 'Thank you for choosing Paperlayer! Is there anything else I can help you with today?')
  CannedResponse.create!(account: account, short_code: 'followup',
                         content: 'I wanted to follow up on your recent inquiry. Have you had a chance to review our quote?')
  CannedResponse.create!(account: account, short_code: 'tracking',
                         content: 'I can help you track your order. Could you please provide your order number?')
  CannedResponse.create!(account: account, short_code: 'samples',
                         content: 'We\'d be happy to send you paper samples! What types of paper are you interested in testing?')

  # Create Macros
  Macro.create!(
    account: account,
    name: 'Handle Bulk Order Inquiry',
    visibility: :global,
    created_by: user,
    actions: [
      { 'action_name' => 'add_label', 'action_params' => [bulk_order_label.title] },
      { 'action_name' => 'assign_team', 'action_params' => [sales_team.id] },
      { 'action_name' => 'send_message',
        'action_params' => ['For bulk orders over 100 reams, we offer competitive wholesale pricing. Let me get you a custom quote. Could you share your estimated monthly paper needs?'] }
    ]
  )

  Macro.create!(
    account: account,
    name: 'Handle Urgent Order',
    visibility: :global,
    created_by: user,
    actions: [
      { 'action_name' => 'add_label', 'action_params' => [urgent_label.title] },
      { 'action_name' => 'change_priority', 'action_params' => ['urgent'] },
      { 'action_name' => 'assign_team', 'action_params' => [operations_team.id] },
      { 'action_name' => 'send_message',
        'action_params' => ['I see you need this urgently. We offer same-day delivery for orders placed before noon. Let me check our inventory and get this expedited for you.'] }
    ]
  )

  Macro.create!(
    account: account,
    name: 'Handle Custom Printing Request',
    visibility: :global,
    created_by: user,
    actions: [
      { 'action_name' => 'add_label', 'action_params' => [custom_print_label.title] },
      { 'action_name' => 'assign_team', 'action_params' => [support_team.id] },
      { 'action_name' => 'send_message',
        'action_params' => ['We provide custom letterhead printing services with a minimum order of 5 reams. Typical turnaround is 5-7 business days. Would you like to discuss your design requirements?'] }
    ]
  )

  Macro.create!(
    account: account,
    name: 'Route to Sales Team',
    visibility: :global,
    created_by: user,
    actions: [
      { 'action_name' => 'add_label', 'action_params' => [pricing_label.title] },
      { 'action_name' => 'assign_team', 'action_params' => [sales_team.id] },
      { 'action_name' => 'send_message',
        'action_params' => ['I\'d be happy to provide pricing information. To give you the most accurate quote, could you let me know: 1) Paper type/weight you need, 2) Quantity required, 3) Delivery location?'] }
    ]
  )

  Macro.create!(
    account: account,
    name: 'Close with Satisfaction Check',
    visibility: :global,
    created_by: user,
    actions: [
      { 'action_name' => 'send_message',
        'action_params' => ['Thank you for choosing Paperlayer! Is there anything else I can help you with today?'] },
      { 'action_name' => 'resolve_conversation' }
    ]
  )

  Macro.create!(
    account: account,
    name: 'Escalate to Operations',
    visibility: :global,
    created_by: user,
    actions: [
      { 'action_name' => 'add_label', 'action_params' => [delivery_label.title] },
      { 'action_name' => 'assign_team', 'action_params' => [operations_team.id] },
      { 'action_name' => 'change_priority', 'action_params' => ['high'] }
    ]
  )

  # ===============================================
  # Create 50 Sample Conversations
  # ===============================================

  agents = [sales_lead, sales_agent_1, sales_agent_2, support_lead, support_agent_1, support_agent_2, operations_lead, operations_agent]

  # Customer names for variety
  customer_names = [
    'Michael Stevens', 'Sarah Parker', 'John Martinez', 'Emily White', 'David Brown',
    'Jennifer Taylor', 'Robert Wilson', 'Lisa Anderson', 'James Thomas', 'Mary Jackson',
    'Christopher Lee', 'Patricia Harris', 'Daniel Clark', 'Linda Lewis', 'Matthew Walker',
    'Barbara Hall', 'Joseph Allen', 'Nancy Young', 'Ryan King', 'Karen Wright',
    'Kevin Lopez', 'Betty Hill', 'Brian Scott', 'Sandra Green', 'George Adams',
    'Jessica Baker', 'Edward Nelson', 'Margaret Carter', 'Steven Mitchell', 'Helen Roberts',
    'Andrew Turner', 'Dorothy Phillips', 'Mark Campbell', 'Carol Parker', 'Paul Evans',
    'Michelle Edwards', 'Donald Collins', 'Ashley Stewart', 'Kenneth Morris', 'Kimberly Rogers',
    'Joshua Reed', 'Amanda Cook', 'Jason Morgan', 'Melissa Bell', 'Justin Murphy',
    'Stephanie Bailey', 'Brandon Rivera', 'Rebecca Cooper', 'Eric Richardson', 'Laura Cox'
  ]

  companies = [
    'Tech Innovations Inc', 'Global Enterprises', 'Summit Corporation', 'Bright Future LLC',
    'Metro Solutions', 'Pacific Group', 'Alliance Partners', 'Premier Services',
    'Apex Industries', 'Horizon Technologies', 'Fusion Consulting', 'Vista Corp',
    'Pinnacle Systems', 'Catalyst Ventures', 'Quantum Labs', 'Nexus Holdings',
    'Zenith Partners', 'Atlas Group', 'Infinity Solutions', 'Eclipse Enterprises'
  ]

  conversation_templates = [
    {
      labels: [bulk_order_label.title, pricing_label.title],
      team: sales_team,
      priority: nil,
      status: :open,
      messages: [
        { role: :incoming, content: 'Hi, I need a quote for 200 cases of copy paper for our office. What kind of pricing can you offer?' },
        { role: :outgoing,
          content: 'Great! For 200 cases, you qualify for our 15% volume discount. That brings the price down to $38.25 per case. Would you like me to prepare a formal quote?' },
        { role: :incoming, content: 'Yes please. How soon can you deliver?' }
      ]
    },
    {
      labels: [custom_print_label.title],
      team: support_team,
      priority: nil,
      status: :pending,
      messages: [
        { role: :incoming, content: 'Do you offer custom letterhead printing? We need about 10 reams with our logo.' },
        { role: :outgoing,
          content: 'Absolutely! We can do custom letterhead with a minimum order of 5 reams. For 10 reams on 28lb premium paper, the cost would be around $200. Turnaround is 5-7 business days. Do you have your design file ready?' }
      ]
    },
    {
      labels: [urgent_label.title, delivery_label.title],
      team: operations_team,
      priority: :urgent,
      status: :open,
      messages: [
        { role: :incoming, content: 'Emergency! We need 50 reams delivered today. Is that possible?' },
        { role: :outgoing, content: 'Yes, we can do same-day delivery within 50 miles if you order before noon. What\'s your location?' },
        { role: :incoming, content: 'We\'re in downtown. How much for rush delivery?' }
      ]
    },
    {
      labels: [product_label.title],
      team: support_team,
      priority: nil,
      status: :resolved,
      messages: [
        { role: :incoming, content: 'What\'s the difference between 20lb and 24lb paper?' },
        { role: :outgoing,
          content: '20lb is our standard weight, great for everyday printing. 24lb is heavier, more professional feel, and less see-through. Perfect for presentations and client-facing documents.' },
        { role: :incoming, content: 'Perfect, I\'ll go with 24lb. Thanks!' }
      ]
    },
    {
      labels: [pricing_label.title],
      team: sales_team,
      priority: nil,
      status: :open,
      messages: [
        { role: :incoming, content: 'Can you send me your current price list for all paper weights?' },
        { role: :outgoing,
          content: 'Of course! I\'ll email you our comprehensive price list. Are you interested in standard sizes or do you need custom dimensions as well?' }
      ]
    },
    {
      labels: [delivery_label.title],
      team: operations_team,
      priority: :high,
      status: :pending,
      messages: [
        { role: :incoming, content: 'My order #12345 hasn\'t arrived yet. It was supposed to be here yesterday.' },
        { role: :outgoing, content: 'I apologize for the delay. Let me track that order for you right away.' }
      ]
    },
    {
      labels: [bulk_order_label.title],
      team: sales_team,
      priority: nil,
      status: :resolved,
      messages: [
        { role: :incoming, content: 'We\'re opening 5 new offices and need to set up a recurring order. Can you help?' },
        { role: :outgoing,
          content: 'Excellent! We have a bulk program perfect for multi-location businesses. With recurring orders over 250 cases, you get 20% off plus a dedicated account manager. When would you like to discuss the details?' },
        { role: :incoming, content: 'That sounds great! Tomorrow at 2 PM works for me.' },
        { role: :outgoing, content: 'Perfect, I\'ve scheduled a call for tomorrow at 2 PM. I\'ll send you a calendar invite shortly.' }
      ]
    },
    {
      labels: [product_label.title, pricing_label.title],
      team: sales_team,
      priority: nil,
      status: :open,
      messages: [
        { role: :incoming, content: 'Do you have recycled paper options? We\'re trying to go green.' },
        { role: :outgoing,
          content: 'Yes! Our Eco-Friendly line is 30% post-consumer recycled content and FSC certified. It\'s $48 per case, just $3 more than standard paper.' }
      ]
    },
    {
      labels: [custom_print_label.title, urgent_label.title],
      team: support_team,
      priority: :urgent,
      status: :open,
      messages: [
        { role: :incoming, content: 'We have a trade show next week and need 1000 business cards ASAP. Can you rush this?' },
        { role: :outgoing,
          content: 'For rush orders, we can turn it around in 2-3 business days for an additional $50 rush fee. Would that work for your timeline?' }
      ]
    },
    {
      labels: [delivery_label.title],
      team: operations_team,
      priority: nil,
      status: :resolved,
      messages: [
        { role: :incoming, content: 'What are your delivery hours? We have limited receiving times.' },
        { role: :outgoing,
          content: 'Our standard delivery window is 9 AM - 5 PM. We can accommodate specific time windows with advance notice. What times work best for you?' },
        { role: :incoming, content: '10 AM - 2 PM would be ideal.' },
        { role: :outgoing, content: 'Noted! I\'ve added that to your account preferences.' }
      ]
    }
  ]

  puts '  Creating 50 diverse conversations...'

  50.times do |i|
    # Create contact
    customer_name = customer_names[i % customer_names.length]
    company = companies[i % companies.length]

    contact_inbox = ContactInboxWithContactBuilder.new(
      source_id: agents.sample.id,
      inbox: [inbox, sales_inbox, support_inbox].sample,
      hmac_verified: true,
      contact_attributes: {
        name: customer_name,
        email: "#{customer_name.downcase.tr(' ', '.')}@#{company.downcase.delete(' ')}.com",
        phone_number: "+1555#{rand(1_000_000..9_999_999)}",
        additional_attributes: {
          company_name: company,
          city: ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia'].sample
        }
      }
    ).perform

    # Pick a template or create variation
    template = conversation_templates[i % conversation_templates.length]

    # Assign to agent from appropriate team
    team_members = TeamMember.where(team: template[:team]).pluck(:user_id)
    assigned_agent = User.find(team_members.sample)

    # Create conversation
    conv = Conversation.create!(
      account: account,
      inbox: contact_inbox.inbox,
      status: template[:status],
      assignee: assigned_agent,
      contact: contact_inbox.contact,
      contact_inbox: contact_inbox,
      priority: template[:priority],
      additional_attributes: {
        initiated_at: {
          timestamp: rand(30).days.ago.to_i
        }
      }
    )

    # Add labels
    conv.label_list.add(*template[:labels])
    conv.save!

    # Create messages
    template[:messages].each do |msg_template|
      sender = msg_template[:role] == :incoming ? contact_inbox.contact : assigned_agent
      Message.create!(
        content: msg_template[:content],
        account: account,
        inbox: contact_inbox.inbox,
        conversation: conv,
        sender: sender,
        message_type: msg_template[:role]
      )
    end
  end

  # Create one special conversation with interactive messages
  special_contact = ContactInboxWithContactBuilder.new(
    source_id: sales_lead.id,
    inbox: inbox,
    hmac_verified: true,
    contact_attributes: {
      name: 'Demo Customer',
      email: 'demo@example.com',
      phone_number: '+15551234567'
    }
  ).perform

  demo_conversation = Conversation.create!(
    account: account,
    inbox: inbox,
    status: :open,
    assignee: sales_lead,
    contact: special_contact.contact,
    contact_inbox: special_contact,
    additional_attributes: {}
  )
  demo_conversation.label_list.add(bulk_order_label.title)
  demo_conversation.save!

  Message.create!(content: 'Hi! I\'m interested in learning more about your products.', account: account, inbox: inbox,
                  conversation: demo_conversation, sender: special_contact.contact, message_type: :incoming)

  # Add interactive message samples
  Seeders::MessageSeeder.create_sample_cards_message demo_conversation
  Seeders::MessageSeeder.create_sample_input_select_message demo_conversation
  Seeders::MessageSeeder.create_sample_form_message demo_conversation
  Seeders::MessageSeeder.create_sample_articles_message demo_conversation
  Seeders::MessageSeeder.create_sample_email_collect_message demo_conversation
  Seeders::MessageSeeder.create_sample_csat_collect_message demo_conversation

  puts '  ✓ Created 50+ conversations with diverse scenarios'

  # ===============================================
  # Help Center Portal Setup
  # ===============================================
  portal = Portal.create!(
    account: account,
    name: 'Paperlayer Help Center',
    slug: 'dunder-mifflin-help',
    page_title: 'Paperlayer Paper Company - Help & Support',
    header_text: 'How can we help you with your paper needs?',
    homepage_link: 'https://paperlayer.com',
    color: '#0066CC',
    config: {
      'allowed_locales' => ['en'],
      'default_locale' => 'en'
    }
  )

  # Category: Getting Started
  getting_started_category = Category.create!(
    account: account,
    portal: portal,
    name: 'Getting Started',
    slug: 'getting-started',
    description: 'Learn the basics of ordering from Paperlayer',
    locale: 'en',
    position: 1,
    icon: 'book-open'
  )

  Article.create!(
    account: account,
    portal: portal,
    category: getting_started_category,
    author: user,
    title: 'How to Place Your First Order',
    description: 'Step-by-step guide to placing your first paper order with Paperlayer',
    content: "# How to Place Your First Order\n\nWelcome to Paperlayer! We're excited to help you with your paper needs.\n\n## Step 1: Browse Our Products\nVisit our product catalog to explore our wide range of paper products:\n- Copy Paper (20lb, 24lb, 28lb, 32lb)\n- Cardstock (65lb, 80lb, 110lb)\n- Specialty Papers (colored, glossy, recycled)\n\n## Step 2: Request a Quote\nContact our sales team via:\n- Live chat on our website\n- Email: sales@paperlayer.com\n- Phone: 1-800-PAPER-01\n\n## Step 3: Review and Approve\nOur team will send you a detailed quote within 24 hours.\n\n## Step 4: Place Your Order\nOnce approved, we'll process your order and provide tracking information.\n\n## Step 5: Delivery\nStandard delivery: 2-3 business days\nSame-day delivery: Available for local orders placed before noon",
    status: :published,
    locale: 'en'
  )

  Article.create!(
    account: account,
    portal: portal,
    category: getting_started_category,
    author: user,
    title: 'Understanding Paper Weights',
    description: 'Learn about different paper weights and their best uses',
    content: "# Understanding Paper Weights\n\nPaper weight can be confusing. Let us help you choose the right weight for your needs.\n\n## Copy Paper Weights\n\n### 20lb (75 gsm) - Standard\n- Most common weight for everyday printing\n- Great for internal documents, drafts\n- Economical choice for high-volume printing\n\n### 24lb (90 gsm) - Premium\n- Heavier feel, more professional\n- Ideal for presentations, resumes\n- Less see-through than 20lb\n\n### 28lb (105 gsm) - Super Premium\n- Excellent for important documents\n- Professional brochures\n- High-quality letterhead\n\n### 32lb (120 gsm) - Ultra Premium\n- Luxury feel and appearance\n- Executive communications\n- Certificates and awards\n\n## Cardstock Weights\n\n### 65lb (176 gsm) - Light Cardstock\n- Greeting cards, postcards\n- Thin presentations\n\n### 80lb (216 gsm) - Medium Cardstock\n- Business cards\n- Invitations\n\n### 110lb (298 gsm) - Heavy Cardstock\n- Premium business cards\n- High-end invitations\n- Display materials\n\n## Need Help?\nContact our team at sales@paperlayer.com or call 1-800-PAPER-01",
    status: :published,
    locale: 'en'
  )

  # Category: Products & Pricing
  products_category = Category.create!(
    account: account,
    portal: portal,
    name: 'Products & Pricing',
    slug: 'products-pricing',
    description: 'Information about our paper products and pricing',
    locale: 'en',
    position: 2,
    icon: 'tag'
  )

  Article.create!(
    account: account,
    portal: portal,
    category: products_category,
    author: user,
    title: 'Copy Paper Product Line',
    description: 'Complete guide to our copy paper offerings',
    content: "# Copy Paper Product Line\n\nPaperlayer offers the finest copy paper in the Northeast.\n\n## Standard Copy Paper\n**Premium White - 20lb**\n- Price: $45 per case (10 reams)\n- Brightness: 92\n- Size: 8.5\" x 11\"\n- Sheets per ream: 500\n\n**Premium White - 24lb**\n- Price: $52 per case (10 reams)\n- Brightness: 94\n- Size: 8.5\" x 11\"\n- Sheets per ream: 500\n\n## Premium Copy Paper\n**Ultra White - 28lb**\n- Price: $65 per case (10 reams)\n- Brightness: 96\n- Perfect for presentations\n\n**Executive White - 32lb**\n- Price: $78 per case (10 reams)\n- Brightness: 98\n- Luxury feel and appearance\n\n## Recycled Paper\n**Eco-Friendly - 20lb**\n- Price: $48 per case (10 reams)\n- 30% post-consumer content\n- FSC certified\n\n## Volume Discounts\n- 50-99 cases: 10% off\n- 100-249 cases: 15% off\n- 250+ cases: 20% off\n\nContact us for custom quotes!",
    status: :published,
    locale: 'en'
  )

  Article.create!(
    account: account,
    portal: portal,
    category: products_category,
    author: user,
    title: 'Bulk Order Discounts',
    description: 'Learn about our volume pricing tiers and save on large orders',
    content: "# Bulk Order Discounts\n\nThe more you order, the more you save with Paperlayer!\n\n## Discount Tiers\n\n### Tier 1: 50-99 Cases\n- **10% discount**\n- Minimum order: 50 cases\n- Perfect for medium-sized offices\n\n### Tier 2: 100-249 Cases\n- **15% discount**\n- Quarterly supply option\n- Dedicated account manager\n\n### Tier 3: 250+ Cases\n- **20% discount**\n- Annual contract pricing\n- Priority customer service\n- Free delivery\n- Flexible payment terms\n\n## Example Savings\n\n**Standard scenario: 100 cases of Premium White 20lb**\n- Regular price: $4,500\n- With 15% discount: $3,825\n- **You save: $675!**\n\n## Additional Benefits\n- No order minimums after initial bulk purchase\n- Locked-in pricing for contract duration\n- Scheduled deliveries\n- Custom invoicing options\n\n## Get Started\nContact our bulk sales team:\n- Email: bulk@paperlayer.com\n- Phone: 1-800-BULK-PAPER\n- Live chat: Available 9 AM - 6 PM EST",
    status: :published,
    locale: 'en'
  )

  # Category: Shipping & Delivery
  shipping_category = Category.create!(
    account: account,
    portal: portal,
    name: 'Shipping & Delivery',
    slug: 'shipping-delivery',
    description: 'Delivery options, shipping costs, and tracking information',
    locale: 'en',
    position: 3,
    icon: 'truck'
  )

  Article.create!(
    account: account,
    portal: portal,
    category: shipping_category,
    author: user,
    title: 'Delivery Options & Times',
    description: 'Choose the delivery option that works best for you',
    content: "# Delivery Options & Times\n\n## Standard Delivery (FREE)\n- **Timeframe:** 2-3 business days\n- **Available:** All orders over $100\n- **Coverage:** Within 200 miles of Scranton, PA\n\n## Express Delivery\n- **Timeframe:** Next business day\n- **Cost:** $25 flat fee\n- **Coverage:** Within 100 miles\n- **Cutoff:** Order by 3 PM\n\n## Same-Day Delivery\n- **Timeframe:** Within 6 hours\n- **Cost:** $50 flat fee\n- **Coverage:** Within 50 miles\n- **Cutoff:** Order by 12 PM noon\n\n## Freight Shipping (Bulk Orders)\n- **Timeframe:** 3-5 business days\n- **Cost:** Varies by distance and volume\n- **Available:** Orders over 100 cases\n- **Includes:** Forklift delivery available\n\n## Tracking Your Order\nAll orders include:\n- Real-time tracking number\n- Email notifications\n- Estimated delivery window\n- Delivery signature confirmation\n\n## Delivery Notes\n- Residential deliveries available\n- Loading dock delivery preferred for bulk\n- Inside delivery available (additional fee)\n- Weather delays may occur\n\nQuestions? Contact: logistics@paperlayer.com",
    status: :published,
    locale: 'en'
  )

  # Category: Custom Services
  custom_category = Category.create!(
    account: account,
    portal: portal,
    name: 'Custom Services',
    slug: 'custom-services',
    description: 'Custom printing, letterhead, and specialty services',
    locale: 'en',
    position: 4,
    icon: 'printer'
  )

  Article.create!(
    account: account,
    portal: portal,
    category: custom_category,
    author: user,
    title: 'Custom Letterhead & Business Stationery',
    description: 'Professional custom printing services for your business',
    content: "# Custom Letterhead & Business Stationery\n\nMake a lasting impression with custom-printed materials from Paperlayer.\n\n## Letterhead Services\n\n### Standard Letterhead\n- **Minimum order:** 5 reams (2,500 sheets)\n- **Turnaround:** 5-7 business days\n- **Paper weight:** 24lb or 28lb\n- **Colors:** Up to 4-color process\n- **Starting at:** $15 per ream\n\n### Premium Letterhead\n- **Minimum order:** 5 reams\n- **Turnaround:** 7-10 business days\n- **Paper weight:** 32lb premium stock\n- **Options:** Embossing, foil stamping\n- **Starting at:** $25 per ream\n\n## Business Cards\n- Standard: 14pt cardstock\n- Premium: 16pt with UV coating\n- Minimum: 500 cards\n- Turnaround: 3-5 business days\n\n## Envelopes\n- Custom printed envelopes\n- Standard #10 size\n- Match your letterhead design\n- Minimum: 500 envelopes\n\n## Design Services\n- Professional design assistance: $150\n- Logo digitization: $75\n- Proof revisions: Included (up to 3)\n\n## The Process\n\n1. **Submit your design** - Email to custom@paperlayer.com\n2. **Review proof** - We'll send a digital proof within 2 business days\n3. **Approve** - Make any needed revisions\n4. **Production** - We print your order\n5. **Delivery** - Ships via your chosen method\n\n## File Requirements\n- Format: PDF, AI, or EPS\n- Resolution: 300 DPI minimum\n- Color mode: CMYK\n- Bleed: 0.125\" on all sides\n\nNeed help with design? We can assist!\nEmail: custom@paperlayer.com\nPhone: 1-800-CUSTOM-PAPER",
    status: :published,
    locale: 'en'
  )

  # ===============================================
  # Captain Assistant Setup (Enterprise Feature)
  # ===============================================
  if defined?(Captain::Assistant)
    captain_assistant = Captain::Assistant.create!(
      account: account,
      name: 'Paper Expert',
      description: 'AI assistant specialized in helping customers with all their paper product needs, from product selection to bulk orders.',
      config: {
        temperature: 0.7,
        feature_faq: true,
        feature_memory: true,
        product_name: 'Paperlayer Paper Products'
      },
      response_guidelines: [
        'Always be friendly and professional',
        'Use paper industry terminology when appropriate',
        'Provide specific product recommendations based on customer needs',
        'Mention bulk discounts when discussing large orders',
        'Offer to connect customers with sales team for custom quotes'
      ],
      guardrails: [
        'Do not discuss competitor products',
        'Do not make promises about delivery times without confirming inventory',
        'Always verify bulk pricing with sales team for orders over 250 cases'
      ]
    )

    # Connect assistant to inbox
    CaptainInbox.create!(
      captain_assistant: captain_assistant,
      inbox: inbox
    )

    # Scenario 1: Product Recommendations
    Captain::Scenario.create!(
      account: account,
      assistant: captain_assistant,
      title: 'Product Recommendations',
      description: 'Help customers choose the right paper products for their needs',
      instruction: "When a customer asks about which paper to use, ask clarifying questions:\n1. What will they use it for? (everyday printing, presentations, letterhead, etc.)\n2. What's their volume? (help them understand bulk discounts)\n3. Do they have any special requirements? (recycled, brightness, specific sizes)\n\nThen recommend appropriate products from our catalog:\n- 20lb for everyday use\n- 24lb for professional documents\n- 28lb for presentations\n- 32lb for executive communications\n- Cardstock for business cards\n\nAlways mention relevant discounts and offer to connect them with sales for quotes.",
      enabled: true
    )

    # Scenario 2: Bulk Orders
    Captain::Scenario.create!(
      account: account,
      assistant: captain_assistant,
      title: 'Bulk Order Processing',
      description: 'Guide customers through bulk order process and pricing',
      instruction: "For bulk order inquiries:\n1. Determine their quantity needs\n2. Explain applicable discount tiers:\n   - 50-99 cases: 10% off\n   - 100-249 cases: 15% off\n   - 250+ cases: 20% off\n3. Calculate estimated savings\n4. Explain additional benefits (account manager, flexible terms)\n5. Offer to connect with bulk sales team for formal quote\n6. Add the 'bulk-order' label to the conversation",
      enabled: true
    )

    # Scenario 3: Shipping Questions
    Captain::Scenario.create!(
      account: account,
      assistant: captain_assistant,
      title: 'Shipping & Delivery',
      description: 'Answer questions about delivery options and times',
      instruction: "When customers ask about shipping:\n1. Standard delivery: 2-3 business days (FREE over $100)\n2. Express: Next day ($25)\n3. Same-day: Within 6 hours, order by noon ($50)\n4. Bulk freight: 3-5 days for 100+ cases\n\nMention tracking is included with all orders.\nFor urgent needs, emphasize same-day delivery within 50 miles.",
      enabled: true
    )

    # Document 1: FAQ - General Questions
    Captain::Document.create!(
      account: account,
      assistant: captain_assistant,
      name: 'General FAQs',
      external_link: 'https://paperlayer.com/faq/general',
      content: "# Frequently Asked Questions\n\n## What are your business hours?\nMonday-Friday: 8 AM - 6 PM EST\nSaturday: 9 AM - 2 PM EST\nSunday: Closed\n\n## Do you offer free shipping?\nYes! Free standard shipping on all orders over $100 within 200 miles of Scranton, PA.\n\n## What payment methods do you accept?\n- Credit cards (Visa, Mastercard, AmEx, Discover)\n- Purchase orders (for established accounts)\n- ACH/Wire transfer\n- Net 30 terms (for qualified businesses)\n\n## Can I return paper products?\nYes, unopened reams can be returned within 30 days for a full refund.\n\n## Do you have a showroom?\nYes! Visit our Scranton office at:\n1725 Slough Avenue\nScranton, PA 18505\n\nAppointments recommended.\n\n## What makes Paperlayer different?\n- Family-owned since 1949\n- Personal service from dedicated account managers\n- Local delivery and same-day service\n- Competitive pricing with volume discounts\n- Expert advice on paper selection",
      status: :available
    )

    # Document 2: FAQ - Product Specifications
    Captain::Document.create!(
      account: account,
      assistant: captain_assistant,
      name: 'Product Specifications',
      external_link: 'https://paperlayer.com/faq/products',
      content: "# Product Specifications FAQs\n\n## What does paper brightness mean?\nBrightness is measured on a scale of 0-100. Higher numbers mean whiter, brighter paper.\n- 92: Standard brightness\n- 94-96: Premium brightness\n- 98+: Ultra-premium brightness\n\n## What's the difference between 20lb and 24lb paper?\nThe number refers to the weight of 500 sheets (a ream).\n- 20lb: Standard weight, economical\n- 24lb: Heavier, more professional feel\n- 28lb: Premium weight for presentations\n- 32lb: Luxury weight for executive use\n\n## Is your paper acid-free?\nYes, all our copy paper is acid-free for long-term archival quality.\n\n## Do you carry recycled paper?\nYes! Our Eco-Friendly line contains 30% post-consumer recycled content and is FSC certified.\n\n## What sizes do you offer?\n- Letter: 8.5\" x 11\" (most common)\n- Legal: 8.5\" x 14\"\n- Tabloid: 11\" x 17\"\n- Custom sizes available for bulk orders\n\n## Can I get paper in colors?\nYes! We stock:\n- Pastels: Ivory, Pink, Blue, Green, Yellow\n- Brights: Red, Orange, Purple\n- Custom colors available for bulk orders\n\n## What's the shelf life of paper?\nPaper properly stored in a cool, dry place will last indefinitely.",
      status: :available
    )

    # Document 3: Bulk Ordering Guide
    Captain::Document.create!(
      account: account,
      assistant: captain_assistant,
      name: 'Bulk Ordering Guide',
      external_link: 'https://paperlayer.com/guides/bulk-orders',
      content: "# Bulk Ordering Guide\n\n## Benefits of Bulk Orders\n\n### Cost Savings\n- 50-99 cases: Save 10%\n- 100-249 cases: Save 15%\n- 250+ cases: Save 20%\n\n### Additional Perks\n- Dedicated account manager\n- Priority customer service\n- Flexible payment terms (Net 30/60/90)\n- Free delivery on orders over 100 cases\n- Scheduled recurring deliveries\n- Custom reporting and invoicing\n\n## How to Place a Bulk Order\n\n1. **Contact our bulk sales team**\n   - Email: bulk@paperlayer.com\n   - Phone: 1-800-BULK-PAPER\n   - Chat with us online\n\n2. **Discuss your needs**\n   - Types of paper needed\n   - Estimated monthly/annual volume\n   - Delivery schedule preferences\n\n3. **Receive your custom quote**\n   - Within 24 hours for standard requests\n   - Same day for urgent needs\n\n4. **Review and sign agreement**\n   - No long-term contracts required\n   - Flexible terms available\n\n5. **Start saving!**\n   - Automated ordering available\n   - Just-in-time delivery options\n\n## Storage Tips for Bulk Orders\n- Store in cool, dry place (60-70°F)\n- Keep away from direct sunlight\n- Maintain 40-60% humidity\n- Store flat, not on edge\n- Keep in original packaging until use\n\n## Popular Bulk Order Scenarios\n\n### Small Office (50-100 cases/year)\n- Mix of 20lb and 24lb paper\n- Quarterly deliveries\n- 10% savings tier\n\n### Medium Business (100-250 cases/year)\n- Multiple paper types\n- Monthly deliveries\n- 15% savings tier\n- Account manager included\n\n### Large Corporation (250+ cases/year)\n- Enterprise agreement\n- Custom delivery schedule\n- 20% savings tier\n- Premium support\n\n## Questions?\nContact our bulk sales specialists:\nbulk@paperlayer.com",
      status: :available
    )

    # Document 4: Custom Printing Guide
    Captain::Document.create!(
      account: account,
      assistant: captain_assistant,
      name: 'Custom Printing Services',
      external_link: 'https://paperlayer.com/services/custom-printing',
      content: "# Custom Printing Services\n\n## What We Offer\n\n### Letterhead\n- Professional custom letterhead\n- Minimum: 5 reams (2,500 sheets)\n- Paper options: 24lb, 28lb, or 32lb\n- Full color printing\n- Turnaround: 5-10 business days\n\n### Business Cards\n- Premium cardstock\n- Standard or custom sizes\n- Options: matte, gloss, UV coating\n- Minimum: 500 cards\n- Turnaround: 3-5 business days\n\n### Envelopes\n- Custom printed envelopes\n- Match your letterhead\n- Multiple sizes available\n- Minimum: 500 envelopes\n\n## Design Services\n\nNeed help with design?\n- Professional design: $150\n- Logo digitization: $75\n- Free setup for repeat orders\n- Up to 3 proof revisions included\n\n## File Requirements\n- Preferred format: PDF, AI, EPS\n- Resolution: 300 DPI minimum\n- Color mode: CMYK (not RGB)\n- Include 0.125\" bleed\n- Embed all fonts\n\n## Approval Process\n\n1. Submit your design or request assistance\n2. Receive digital proof within 2 business days\n3. Review and approve (or request changes)\n4. Production begins upon approval\n5. Delivery within specified timeframe\n\n## Pricing Examples\n\n**Standard Letterhead (24lb)**\n- 5 reams: $75\n- 10 reams: $140\n- 25 reams: $325\n\n**Premium Letterhead (32lb)**\n- 5 reams: $125\n- 10 reams: $230\n- 25 reams: $525\n\n**Business Cards**\n- 500 cards: $75\n- 1,000 cards: $125\n- 2,500 cards: $275\n\n## Get Started\n\nEmail your project details to:\ncustom@paperlayer.com\n\nOr call: 1-800-CUSTOM-PAPER",
      status: :available
    )

    puts '  ✓ Captain Assistant created with documents and scenarios'
  else
    puts '  ⚠ Captain Assistant is an Enterprise feature - skipping'
  end
end
