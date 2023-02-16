class MicrosoftController < ApplicationController
  after_action :set_version_header

  def identity_association
    microsoft_indentity
  end

  private

  def set_version_header
    response.headers['Content-Length'] = { associatedApplications: [{ applicationId: @identity_json }] }.to_json.length
  end

  def microsoft_indentity
    @identity_json = ENV.fetch('AZURE_APP_ID', nil)
  end
end
