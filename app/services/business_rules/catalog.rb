# frozen_string_literal: true

module BusinessRules
  class Catalog
    GUARD_TYPES = %w[
      require_attributes_on_status
      if_attribute_then_require
      require_reason_on_status
      forbid_status_if
      require_assignee_on_status
    ].freeze

    class << self
      def presets
        [
          {
            'id' => 'require_on_resolve',
            'family' => 'guard',
            'type' => 'require_attributes_on_status',
            'name_key' => 'BUSINESS_RULES.PRESETS.REQUIRE_ON_RESOLVE',
            'description_key' => 'BUSINESS_RULES.PRESETS.REQUIRE_ON_RESOLVE_DESC',
            'defaults' => {
              'type' => 'require_attributes_on_status',
              'enabled' => true,
              'config' => { 'status' => 'resolved', 'attribute_keys' => [] }
            }
          },
          {
            'id' => 'if_x_require_yz',
            'family' => 'guard',
            'type' => 'if_attribute_then_require',
            'name_key' => 'BUSINESS_RULES.PRESETS.IF_X_REQUIRE_YZ',
            'description_key' => 'BUSINESS_RULES.PRESETS.IF_X_REQUIRE_YZ_DESC',
            'defaults' => {
              'type' => 'if_attribute_then_require',
              'enabled' => true,
              'config' => {
                'when_attribute' => '',
                'when_values' => [],
                'require_attribute_keys' => [],
                'on_status' => 'resolved'
              }
            }
          },
          {
            'id' => 'motivo_al_posponer',
            'family' => 'guard',
            'type' => 'require_reason_on_status',
            'name_key' => 'BUSINESS_RULES.PRESETS.MOTIVO_POSPONER',
            'description_key' => 'BUSINESS_RULES.PRESETS.MOTIVO_POSPONER_DESC',
            'defaults' => {
              'type' => 'require_reason_on_status',
              'enabled' => true,
              'config' => {
                'statuses' => %w[pending snoozed],
                'require_private_note' => true,
                'reason_attribute_key' => ''
              }
            }
          },
          {
            'id' => 'forbid_resolve_label',
            'family' => 'guard',
            'type' => 'forbid_status_if',
            'name_key' => 'BUSINESS_RULES.PRESETS.FORBID_RESOLVE_LABEL',
            'description_key' => 'BUSINESS_RULES.PRESETS.FORBID_RESOLVE_LABEL_DESC',
            'defaults' => {
              'type' => 'forbid_status_if',
              'enabled' => false,
              'config' => { 'status' => 'resolved', 'label' => '' }
            }
          },
          {
            'id' => 'require_assignee_on_open',
            'family' => 'guard',
            'type' => 'require_assignee_on_status',
            'name_key' => 'BUSINESS_RULES.PRESETS.REQUIRE_ASSIGNEE_ON_OPEN',
            'description_key' => 'BUSINESS_RULES.PRESETS.REQUIRE_ASSIGNEE_ON_OPEN_DESC',
            'defaults' => {
              'type' => 'require_assignee_on_status',
              'enabled' => false,
              'config' => { 'status' => 'open', 'require_team_or_agent' => true }
            }
          },
          {
            'id' => 'post_compra_n_dias',
            'family' => 'time',
            'type' => 'time_triggered',
            'name_key' => 'BUSINESS_RULES.PRESETS.POST_COMPRA',
            'description_key' => 'BUSINESS_RULES.PRESETS.POST_COMPRA_DESC',
            'defaults' => {
              'event_name' => 'time_triggered',
              # Prod DFIT key; leave blank only if account has no sale-date CA.
              'schedule' => { 'kind' => 'days_since_attribute', 'attribute_key' => 'fecha_venta', 'days' => 15 },
              'conditions' => [],
              'actions' => [{ 'action_name' => 'add_label', 'action_params' => ['seguimiento'] }]
            }
          },
          {
            'id' => 'followup_sin_respuesta',
            'family' => 'time',
            'type' => 'time_triggered',
            'name_key' => 'BUSINESS_RULES.PRESETS.FOLLOWUP_24H',
            'description_key' => 'BUSINESS_RULES.PRESETS.FOLLOWUP_24H_DESC',
            'defaults' => {
              'event_name' => 'time_triggered',
              'schedule' => { 'kind' => 'hours_since_last_outgoing', 'hours' => 24 },
              'conditions' => [],
              'actions' => [{
                'action_name' => 'send_message',
                'action_params' => ['Hola {{contact.name}}, ¿qué pasó? ¿Te animaste?']
              }]
            }
          },
          {
            'id' => 'seguimiento_30d',
            'family' => 'time',
            'type' => 'time_triggered',
            'name_key' => 'BUSINESS_RULES.PRESETS.SEGUIMIENTO_30D',
            'description_key' => 'BUSINESS_RULES.PRESETS.SEGUIMIENTO_30D_DESC',
            'defaults' => {
              'event_name' => 'time_triggered',
              'schedule' => {
                'kind' => 'days_since_attribute',
                # Prod DFIT uses fecha_seguimiento; ultimo_seguimiento is a local alias only.
                'attribute_key' => 'fecha_seguimiento',
                'days' => 30
              },
              'conditions' => [{
                'attribute_key' => 'status',
                'filter_operator' => 'equal_to',
                'values' => ['open'],
                'query_operator' => nil,
                'custom_attribute_type' => ''
              }],
              'actions' => [
                {
                  'action_name' => 'send_message',
                  'action_params' => [
                    'Hola {{contact.name}}, te escribimos para dar seguimiento. ¿Cómo va todo?'
                  ]
                },
                {
                  'action_name' => 'update_conversation_custom_attribute',
                  'action_params' => [{
                    'attribute_key' => 'fecha_seguimiento',
                    'value' => '{{ date.today }}'
                  }]
                },
                { 'action_name' => 'notify_assignee', 'action_params' => [] }
              ]
            }
          }
        ]
      end

      def guard_presets
        presets.select { |p| p['family'] == 'guard' }
      end

      def time_presets
        presets.select { |p| p['family'] == 'time' }
      end

      def find(id)
        presets.find { |p| p['id'] == id.to_s }
      end
    end
  end
end
