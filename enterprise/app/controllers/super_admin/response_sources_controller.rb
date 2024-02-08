class SuperAdmin::ResponseSourcesController < SuperAdmin::ApplicationController
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
    robin_response = ChatGpt.new(response_sections(params[:message])).generate_response('', previous_messages)
    render json: { message: "#{robin_response['response']} \n context_ids:  #{robin_response['context_ids']}" }
  end

  private

  # refer response_bot_service.rb
  def get_previous_messages(previous_messages)
    # TODO: Implement a redis based temporary storage for previous messages in the Chat
    # At the moment we are not handling previous response, but on actual inbox bots we are
    # So we need to implement a temporary storage for previous messages to replicate exact behavior
  end

  def response_sections(query)
    embedding = Openai::EmbeddingsService.new.get_embedding(query)

    sections = ''
    @response_source.responses.active.nearest_neighbors(:embedding, embedding, distance: 'cosine').first(5).each do |response|
      sections += "{context_id: #{response.id}, context: #{response.question} ? #{response.answer}},"
    end
    sections
  end

  def set_response_source
    @response_source = requested_resource
  end
end
