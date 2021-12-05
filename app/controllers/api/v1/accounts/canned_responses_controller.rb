class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  before_action :fetch_canned_response, only: [:update, :destroy]

  def index
    render json: canned_responses
  end

  def create
    @canned_response = Current.account.canned_responses.new(canned_response_params)
    @canned_response.save!
    render json: @canned_response
  end

  def update
    @canned_response.update!(canned_response_params)
    render json: @canned_response
  end

  def destroy
    @canned_response.destroy
    head :ok
  end

  private

  def fetch_canned_response
    @canned_response = Current.account.canned_responses.find(params[:id])
  end

  def canned_response_params
    params.require(:canned_response).permit(:short_code, :content)
  end

  def template_variables(contact:)
    contact_data = {
      name: contact.name,
      email: contact.email,
      phone: contact.phone_number
    }.merge(contact.custom_attributes)
    variables = {}
    contact_data.each_key do |key|
      variables["requester_#{key}"] = contact_data[key]
    end
    variables
  end

  def canned_responses
    responses = Current.account.canned_responses
    responses = responses.where('short_code ILIKE ?', "#{params[:search]}%") if params[:search]
    if params[:conversation_id]
      conversation = Current.account.conversations.find(params[:conversation_id])
      if conversation
        # we need to templatize the canned responses
        # with these values
        # ticket.requester -> name, email, phone ...custom_attributes
        responses = responses.map do |response|
          template = Liquid::Template.parse(response.content)
          response.content = template.render(template_variables(contact: conversation.contact))
          response
        end
      end
    end
    responses
  end
end
