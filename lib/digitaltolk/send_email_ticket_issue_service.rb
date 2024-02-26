class Digitaltolk::SendEmailTicketIssueService
  attr_accessor :account, :user, :params, :errors, :conversation

  def initialize(account, user, params)
    @account = account
    @user = user
    @params = params
    @errors = []
  end

  def perform
    service = Digitaltolk::SendEmailTicketService.new(account, user, params, for_issue: true)
    result = service.perform
    @errors = service.errors
    
    result
  end
end