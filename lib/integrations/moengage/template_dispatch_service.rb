class Integrations::Moengage::TemplateDispatchService
  def initialize(event_name:, payload:, contact:, conversation:, hook:)
    @event_name = event_name
    @payload = payload.with_indifferent_access
    @contact = contact
    @conversation = conversation
    @hook = hook
  end

  def perform
    mapping = find_mapping
    return { status: :no_mapping } unless mapping

    inbox = mapping.inbox
    return { status: :invalid_inbox, error: 'Inbox is not a WhatsApp channel' } unless whatsapp_inbox?(inbox)

    template = find_approved_template(inbox, mapping)
    return { status: :template_not_found, error: "Template '#{mapping.template_name}' not found or not approved" } unless template

    template_params = build_template_params(mapping, template)
    message = create_message(inbox, template_params)
    dispatch_reply(message)

    { status: :sent, template: mapping.template_name, message_id: message.id }
  end

  private

  attr_reader :event_name, :payload, :contact, :conversation, :hook

  def find_mapping
    hook.moengage_template_mappings.active.for_event(event_name).first
  end

  def whatsapp_inbox?(inbox)
    inbox.channel_type == 'Channel::Whatsapp'
  end

  def find_approved_template(inbox, mapping)
    inbox.channel.message_templates&.find do |t|
      t['name'] == mapping.template_name &&
        t['language'] == mapping.template_language &&
        t['status']&.downcase == 'approved'
    end
  end

  def build_template_params(mapping, template)
    resolved = resolve_parameters(mapping.parameter_map)

    {
      'name' => mapping.template_name,
      'namespace' => template['namespace'],
      'language' => mapping.template_language,
      'processed_params' => resolved
    }
  end

  def resolve_parameters(parameter_map)
    resolved = {}

    parameter_map.each do |section, value|
      resolved[section] = case section
                          when 'buttons'
                            resolve_buttons(value)
                          else
                            resolve_section(value)
                          end
    end

    resolved
  end

  def resolve_section(section_map)
    return section_map unless section_map.is_a?(Hash)

    section_map.transform_values { |path| resolve_dot_path(path) }
  end

  def resolve_buttons(buttons_array)
    return buttons_array unless buttons_array.is_a?(Array)

    buttons_array.map do |button|
      next button unless button.is_a?(Hash)

      button.transform_values do |value|
        value.is_a?(String) && value.include?('.') ? resolve_dot_path(value) : value
      end
    end
  end

  def resolve_dot_path(path)
    return path unless path.is_a?(String)

    keys = path.split('.')
    keys.reduce(payload) do |current, key|
      return path unless current.is_a?(Hash) || current.is_a?(ActiveSupport::HashWithIndifferentAccess)

      current[key]
    end || path
  end

  def create_message(_inbox, template_params)
    sender = conversation.account.users.where(type: nil).first

    Messages::MessageBuilder.new(
      sender,
      conversation,
      {
        content: '',
        message_type: :outgoing,
        private: false,
        template_params: template_params,
        content_attributes: {
          'moengage_template_dispatch' => true,
          'moengage_event' => event_name
        }
      }
    ).perform
  end

  def dispatch_reply(message)
    ::SendReplyJob.perform_later(message.id)
  end
end
