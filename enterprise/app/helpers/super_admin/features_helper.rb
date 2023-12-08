module SuperAdmin::FeaturesHelper
  def self.available_features
    {
      custom_branding: {
        name: 'Custom Branding',
        description: 'Apply your own branding to this installation.',
        enabled: (ChatwootHub.pricing_plan != 'community')
      },
      agent_capacity: {
        name: 'Agent Capacity',
        description: 'Set limits to auto-assigning conversations to your agents.',
        enabled: (ChatwootHub.pricing_plan != 'community')
      },
      audit_logs: {
        name: 'Audit Logs',
        description: 'Track and trace account activities with ease with detailed audit logs.',
        enabled: (ChatwootHub.pricing_plan != 'community')
      },
      disable_branding: {
        name: 'Disable Branding',
        description: 'Disable branding on live-chat widget and external emails.',
        enabled: (ChatwootHub.pricing_plan != 'community')
      },
      live_chat: {
        name: 'Live Chat',
        description: 'Improve your customer experience using a live chat on your website.',
        enabled: true
      },
      email: {
        name: 'Email',
        description: 'Manage your email customer interactions from Chatwoot.',
        enabled: true
      },
      messenger: {
        name: 'Messenger',
        description: 'Stay connected with your customers on Facebook & Instagram.',
        enabled: true
      },
      whatsapp: {
        name: 'WhatsApp',
        description: 'Manage your WhatsApp business interactions from Chatwoot.',
        enabled: true
      },
      telegram: {
        name: 'Telegram',
        description: 'Manage your Telegram customer interactions from Chatwoot.',
        enabled: true
      },
      line: {
        name: 'Line',
        description: 'Manage your Line customer interactions from Chatwoot.',
        enabled: true
      },
      sms: {
        name: 'SMS',
        description: 'Manage your SMS customer interactions from Chatwoot.',
        enabled: true
      },
      help_center: {
        name: 'Help Center',
        description: 'Allow agents to create help center articles and publish them in a portal.',
        enabled: true
      }
    }
  end
end
