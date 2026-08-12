class Captain::Routines::Operations::Base
  class << self
    attr_reader :operation_name, :effect, :description, :arguments, :required_arguments

    def configure(name:, **definition)
      @operation_name = name
      @effect = definition.fetch(:effect)
      @description = definition.fetch(:description)
      @arguments = definition.fetch(:arguments).freeze
      @required_arguments = definition.fetch(:required, []).map(&:to_s).freeze
    end

    def definition
      {
        kind: kind,
        effect: effect,
        description: description,
        arguments: arguments,
        required: required_arguments
      }
    end

    def execute(context:, arguments:)
      new(context).execute(**arguments.symbolize_keys)
    end
  end

  def initialize(context)
    @context = context
  end

  private

  attr_reader :context

  delegate :account, :started_at, to: :context

  def conversation!(value)
    account.conversations.find(record_id(value))
  end

  def contact!(value)
    account.contacts.find(record_id(value))
  end

  def inbox!(value)
    resolve_record!(account.inboxes, value, %i[name])
  end

  def team!(value)
    resolve_record!(account.teams, value, %i[name])
  end

  def agent!(value)
    resolve_record!(account.users, value, %i[email name])
  end

  def label!(value)
    resolve_record!(account.labels, value, %i[title])
  end

  def record_id(value)
    return value['id'] || value[:id] if value.is_a?(Hash)

    value
  end

  def resolve_record!(scope, value, fields)
    id = record_id(value)
    return scope.find(id) if id.to_s.match?(/\A\d+\z/)

    matches = fields.map { |field| scope.where("LOWER(#{scope.klass.table_name}.#{field}) = ?", id.to_s.downcase) }
    matches.reduce { |combined, relation| combined.or(relation) }.sole
  end

  def conversation_data(conversation)
    {
      'id' => conversation.id,
      'display_id' => conversation.display_id,
      'status' => conversation.status,
      'priority' => conversation.priority,
      'created_at' => conversation.created_at.iso8601,
      'last_activity_at' => conversation.last_activity_at.iso8601,
      'waiting_since' => conversation.waiting_since&.iso8601,
      'snoozed_until' => conversation.snoozed_until&.iso8601,
      'labels' => conversation.label_list,
      'custom_attributes' => conversation.custom_attributes,
      'additional_attributes' => conversation.additional_attributes,
      'contact' => contact_data(conversation.contact),
      'inbox' => inbox_data(conversation.inbox),
      'assignee' => agent_data(conversation.assignee),
      'team' => team_data(conversation.team)
    }
  end

  def contact_data(contact)
    return unless contact

    {
      'id' => contact.id,
      'name' => contact.name,
      'email' => contact.email,
      'phone_number' => contact.phone_number,
      'identifier' => contact.identifier,
      'labels' => contact.label_list,
      'custom_attributes' => contact.custom_attributes,
      'additional_attributes' => contact.additional_attributes,
      'last_activity_at' => contact.last_activity_at&.iso8601
    }
  end

  def agent_data(agent)
    return unless agent

    account_user = account.account_users.find_by(user_id: agent.id)
    {
      'id' => agent.id,
      'name' => agent.name,
      'email' => agent.email,
      'availability' => account_user&.availability
    }
  end

  def team_data(team)
    { 'id' => team.id, 'name' => team.name } if team
  end

  def inbox_data(inbox)
    return unless inbox

    { 'id' => inbox.id, 'name' => inbox.name, 'channel_type' => inbox.channel_type, 'timezone' => inbox.timezone }
  end

  def label_data(label)
    { 'id' => label.id, 'title' => label.title, 'description' => label.description, 'color' => label.color }
  end

  def message_data(message)
    sender = if message.sender.is_a?(User)
               agent_data(message.sender)
             elsif message.sender.is_a?(Contact)
               contact_data(message.sender)
             elsif message.sender
               { 'id' => message.sender.id, 'name' => message.sender.try(:name), 'type' => message.sender_type }
             end

    {
      'id' => message.id,
      'message_type' => message.message_type,
      'private' => message.private,
      'content' => message.content,
      'sender' => sender,
      'created_at' => message.created_at.iso8601
    }
  end

  def duration!(value)
    time_parser.duration!(value)
  end

  def time_range!(value)
    time_parser.range!(value)
  end

  def timestamp!(value)
    time_parser.timestamp!(value)
  end

  def time_parser
    @time_parser ||= Captain::Routines::TimeParser.new(reference_time: started_at, timezone: context.routine.timezone)
  end

  def render_content(content)
    Captain::Routines::RichMessageRenderer.render(content)
  end

  def create_message(conversation, content, private:)
    rendered_content = render_content(content)
    raise ArgumentError, 'Message content cannot be blank' if rendered_content.blank?

    message = Messages::MessageBuilder.new(
      nil,
      conversation,
      content: rendered_content,
      private: private,
      content_attributes: {
        captain_routine_id: context.routine.id,
        captain_routine_execution_id: context.id
      }
    ).perform
    message_data(message)
  end
end
