class TaskTemplates::DefaultSeeder
  DEFAULTS = [
    {
      key: 'verify_payment',
      title: 'Verify payment',
      description: 'Validate customer payment or transfer receipt.',
      default_priority: 'high',
      metadata_schema: [
        { 'key' => 'payment_reference', 'label' => 'Payment reference', 'type' => 'string' }
      ],
      position: 0
    },
    {
      key: 'issue_invoice',
      title: 'Issue invoice',
      description: 'Generate and send invoice to the customer.',
      default_priority: 'normal',
      metadata_schema: [
        { 'key' => 'invoice_number', 'label' => 'Invoice number', 'type' => 'string' }
      ],
      position: 1
    },
    {
      key: 'prepare_order',
      title: 'Prepare order',
      description: 'Pick, pack, and prepare the order for shipment.',
      default_priority: 'normal',
      metadata_schema: [],
      position: 2
    },
    {
      key: 'ship_order',
      title: 'Ship order',
      description: 'Hand off order to logistics and register tracking.',
      default_priority: 'normal',
      metadata_schema: [
        { 'key' => 'tracking_number', 'label' => 'Tracking number', 'type' => 'string' },
        { 'key' => 'carrier', 'label' => 'Carrier', 'type' => 'string' }
      ],
      position: 3
    },
    {
      key: 'call_customer',
      title: 'Call customer',
      description: 'Follow up with the customer by phone.',
      default_priority: 'normal',
      metadata_schema: [],
      position: 4
    }
  ].freeze

  pattr_initialize [:account!]

  def perform
    DEFAULTS.each do |attrs|
      account.task_templates.find_or_create_by!(key: attrs[:key]) do |template|
        template.assign_attributes(attrs)
      end
    end
  end
end
