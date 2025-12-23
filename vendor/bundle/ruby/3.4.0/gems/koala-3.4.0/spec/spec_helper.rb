# Quantify coverage
require 'simplecov'
SimpleCov.start

# load the library
require 'koala'

# Support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# set up our testing environment
# load testing data and (if needed) create test users or validate real users
KoalaTest.setup_test_environment!

BEACH_BALL_PATH = File.join(File.dirname(__FILE__), "fixtures", "beach.jpg")

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    # This option should be set when all dependencies are being loaded
    # before a spec run, as is the case in a typical spec helper. It will
    # cause any verifying double instantiation for a class that does not
    # exist to raise, protecting against incorrectly spelt names.
    mocks.verify_doubled_constant_names = true
  end
end
