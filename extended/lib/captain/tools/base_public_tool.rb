class Captain::Tools::BasePublicTool
  class << self
    attr_reader :tool_description, :tool_params

    def description(desc)
      @tool_description = desc
    end

    def param(name, options = {})
      @tool_params ||= {}
      @tool_params[name] = options
    end
  end

  attr_reader :assistant, :user

  def initialize(assistant, user: nil)
    @assistant = assistant
    @user = user
  end

  def active?
    true
  end

  def name
    self.class.name.demodulize.underscore
  end

  def description
    self.class.tool_description
  end

  def permissions
    []
  end

  def to_registry_format
    {
      name: name,
      description: description,
      parameters: {
        type: 'object',
        properties: build_properties,
        required: required_params
      }
    }
  end

  def execute(input)
    perform(nil, **input.symbolize_keys)
  end

  # Abstract method to be implemented by subclasses
  def perform(_tool_context, **_args)
    raise NotImplementedError
  end

  private

  def build_properties
    return {} unless self.class.tool_params

    self.class.tool_params.transform_values do |options|
      {
        type: options[:type] || 'string',
        description: options[:desc]
      }
    end
  end

  def required_params
    return [] unless self.class.tool_params

    self.class.tool_params.select { |_, opts| opts.fetch(:required, true) }.keys
  end

  def account_scoped(model_class)
    model_class.where(account_id: @assistant.account_id)
  end

  def find_conversation(state)
    return unless state&.dig(:conversation, :id)

    account_scoped(::Conversation).find_by(id: state[:conversation][:id])
  end

  def find_contact(state)
    return unless state&.dig(:contact, :id)

    account_scoped(::Contact).find_by(id: state[:contact][:id])
  end

  def log_tool_usage(action, details = {})
    Rails.logger.info("#{self.class.name}: #{action} - #{details.to_json}")
  end
end
