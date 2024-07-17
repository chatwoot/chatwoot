class SuperAdmin::ResponseSourcesController < SuperAdmin::EnterpriseBaseController
  # Overwrite any of the RESTful controller actions to implement custom behavior
  # For example, you may want to send an email after a foo is updated.
  #
  # def update
  #   super
  #   send_foo_updated_email(requested_resource)
  # end

  # Override this method to specify custom lookup behavior.
  # This will be used to set the resource for the `show`, `edit`, and `update`
  # actions.
  #
  # def find_resource(param)
  #   Foo.find_by!(slug: param)
  # end

  # The result of this lookup will be available as `requested_resource`

  # Override this if you have certain roles that require a subset
  # this will be used to set the records shown on the `index` action.
  #
  # def scoped_resource
  #   if current_user.super_admin?
  #     resource_class
  #   else
  #     resource_class.with_less_stuff
  #   end
  # end

  # Override `resource_params` if you want to transform the submitted
  # data before it's persisted. For example, the following would turn all
  # empty values into nil values. It uses other APIs such as `resource_class`
  # and `dashboard`:
  #
  # def resource_params
  #   params.require(resource_class.model_name.param_key).
  #     permit(dashboard.permitted_attributes(action_name)).
  #     transform_values { |value| value == "" ? nil : value }
  # end

  # See https://administrate-demo.herokuapp.com/customizing_controller_actions
  # for more information

  before_action :set_response_source, only: %i[chat process_chat]

  def chat; end

  def process_chat
    previous_messages = []
    get_previous_messages(previous_messages)
    robin_response = ChatGpt.new(
      Enterprise::MessageTemplates::ResponseBotService.response_sections(params[:message], @response_source)
    ).generate_response(
      params[:message], previous_messages
    )
    message_content = robin_response['response']
    if robin_response['context_ids'].present?
      message_content += Enterprise::MessageTemplates::ResponseBotService.generate_sources_section(robin_response['context_ids'])
    end
    render json: { message: message_content }
  end

  private

  def get_previous_messages(previous_messages)
    params[:previous_messages].each do |message|
      role = message['type'] == 'user' ? 'user' : 'system'
      previous_messages << { content: message['message'], role: role }
    end
  end

  def set_response_source
    @response_source = requested_resource
  end
end
