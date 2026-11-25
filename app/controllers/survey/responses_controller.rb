class Survey::ResponsesController < ActionController::Base
  before_action :set_conversation
  before_action :set_global_config

  def show; end

  private

  # find_by, not find_by!: the page has to render for a uuid it does not know, so the Vue app
  # can ask the public endpoint and show the error that comes back. Raising here would put a
  # Rails error page in front of a customer who only mistyped a link.
  #
  # `uuid` is a Postgres uuid column, so a string that is not one casts to nil and the query
  # becomes `WHERE uuid IS NULL` -- no exception to rescue.
  def set_conversation
    @conversation = Conversation.find_by(uuid: params[:id])
  end

  # The contact opening this page is a customer of the account, not of the installation, so
  # the page wears the account's brand. Without a conversation to resolve -- an unknown uuid
  # -- Brand falls back to the installation on its own.
  def set_global_config
    account = @conversation&.account

    @global_config = Brand.for(account: account, inbox: @conversation&.inbox).web_config.merge(
      # Kept out of Brand: this is a plan entitlement, not part of what the brand looks like.
      'DISABLE_BRANDING' => account.present? && account.feature_enabled?('disable_branding')
    )
  end
end
