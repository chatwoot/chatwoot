require 'web_push'
require 'webmock/rspec'
require 'simplecov'

WebMock.disable_net_connect!(allow_localhost: true)
SimpleCov.start

def vapid_options
  {
    subject: 'mailto:sender@example.com',
    public_key: vapid_public_key,
    private_key: vapid_private_key
  }
end

def vapid_public_key
  'BB37UCyc8LLX4PNQSe-04vSFvpUWGrENubUaslVFM_l5TxcGVMY0C3RXPeUJAQHKYlcOM2P4vTYmkoo0VZGZTM4='
end

def vapid_private_key
  'OPrw1Sum3gRoL4-DXfSCC266r-qfFSRZrnj8MgIhRHg='
end
