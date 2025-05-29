class Api::V1::Accounts::Aiagent::TopicsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Aiagent::Topic) }

  before_action :set_topic, only: [:show, :update, :destroy, :playground]

  def index
    @topics = account_topics.ordered
  end

  def show; end

  def create
    @topic = account_topics.create!(topic_params)
  end

  def update
    @topic.update!(topic_params)
  end

  def destroy
    @topic.destroy
    head :no_content
  end

  def playground
    response = Aiagent::Llm::TopicChatService.new(topic: @topic).generate_response(
      params[:message_content],
      message_history
    )

    render json: response
  end

  private

  def set_topic
    @topic = account_topics.find(params[:id])
  end

  def account_topics
    @account_topics ||= Aiagent::Topic.for_account(Current.account.id)
  end

  def topic_params
    params.require(:topic).permit(:name, :description,
                                  config: [
                                    :product_name, :feature_faq, :feature_memory,
                                    :welcome_message, :handoff_message, :resolution_message,
                                    :instructions
                                  ])
  end

  def playground_params
    params.require(:topic).permit(:message_content, message_history: [:role, :content])
  end

  def message_history
    (playground_params[:message_history] || []).map { |message| { role: message[:role], content: message[:content] } }
  end
end
