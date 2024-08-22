class CannedResponseBuilder
  include ::FileTypeHelper
  include ::AttachmentConcern
  attr_reader :canned_response

  def initialize(account, params)
    @params = params
    @account = account
    @attachments = params[:attachments]
  end

  def perform
    @canned_response = @account.canned_responses.build(canned_response_params)
    process_attachments_to_be_added(resource: @canned_response, params: @params)
    @canned_response.save!
    @canned_response
  end

  private

  def canned_response_params
    {
      short_code: @params[:short_code],
      content: @params[:content]
    }
  end
end
