require 'yaml'

require 'rubygems'
require 'test/unit'
require 'mocha/test_unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'gmail_xoauth'

# Wanna debug ? Activate the IMAP debug mode, it will show the client/server conversation
# Net::IMAP.debug = true

# SMTP debugging can only be enabled on Net::SMTP instances
# Net::SMTP.class_eval do
#   def initialize_with_debug(*args)
#     initialize_without_debug(*args)
#     @debug_output = STDERR
#   end
#   alias_method :initialize_without_debug, :initialize
#   alias_method :initialize, :initialize_with_debug
# end

VALID_CREDENTIALS = begin
  YAML.load_file(File.join(File.dirname(__FILE__), 'valid_credentials.yml'))
rescue Errno::ENOENT
  STDERR.puts %(
Warning: some tests are disabled because they require valid credentials. To enable them, create a file \"test/valid_credentials.yml\".
It should contain valid OAuth tokens. Valid tokens oauth tokens can be generated thanks to \"xoauth.py\":http://code.google.com/p/google-mail-xoauth-tools/.
It should also ontain a valid OAuth2 access token. Valid tokens oauth2 tokens can be generated thanks to \"oauth2.py\":http://code.google.com/p/google-mail-oauth2-tools//. Note that oauth2 access tokens are time limited (an hour in my experience).
Of course, this file is .gitignored. Template:

---
:email: someuser@gmail.com
:consumer_key: anonymous # "anonymous" is a valid value for testing
:consumer_secret: anonymous # "anonymous" is a valid value for testing
:token: 1/nE2xBCDOU0429bTeJySE11kRE95qzKQNlfTaaBcDeFg
:token_secret: 123Z/bMsi9fFhN6qHFWOabcd
:oauth2_token: ya29.AHES6ZTIpsLuSyMwnh-3C40WWcuiOe4N7he0a8xnkvDk_6Q_6yUg7E

)
  false
end

class Test::Unit::TestCase
end
