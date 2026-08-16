require 'rails_helper'

RSpec.describe Whatsapp::Providers::BaseService do
  subject(:service) { described_class.new(whatsapp_channel: Object.new) }

  it 'falls back to provider details when the user-facing error message is blank' do
    response = Struct.new(:parsed_response).new(
      {
        'error' => {
          'code' => 131_044,
          'error_user_msg' => '',
          'error_data' => { 'details' => 'Business eligibility check failed' }
        }
      }
    )

    expect(service.send(:parsed_error, response)).to include(message: 'Business eligibility check failed')
  end
end
