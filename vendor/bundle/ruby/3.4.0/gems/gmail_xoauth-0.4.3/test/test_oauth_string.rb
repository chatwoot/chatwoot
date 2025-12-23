require 'helper'

class TestOauthString < Test::Unit::TestCase
  
  def setup
  end
  
  def test_build_oauth_string_should_accept_custom_consumer
    OAuth::Helper.stubs(:generate_key).returns('abc')
    OAuth::Helper.stubs(:generate_timestamp).returns(1274215474)
    
    request_url = "https://mail.google.com/mail/b/user_name@gmail.com/imap/"
    oauth_params = {
      :consumer_key => 'c',
      :consumer_secret => 'd',
      :token => 'a',
      :token_secret => 'b',
    }
    
    oauth_string = C.new.__send__('build_oauth_string', request_url, oauth_params)
    
    assert_equal(
      'oauth_consumer_key="c",oauth_nonce="abc",oauth_signature="eseW9YybDf3fPToiwyLdUwSlfUw%3D",oauth_signature_method="HMAC-SHA1",oauth_timestamp="1274215474",oauth_token="a",oauth_version="1.0"',
      oauth_string
    )
  end
  
  def test_build_oauth_string_should_set_consumer_anonymous_by_default
    OAuth::Helper.stubs(:generate_key).returns('abc')
    OAuth::Helper.stubs(:generate_timestamp).returns(1274215474)
    
    request_url = "https://mail.google.com/mail/b/user_name@gmail.com/imap/"
    oauth_params = {
      :token => 'a',
      :token_secret => 'b',
    }
    
    oauth_string = C.new.__send__('build_oauth_string', request_url, oauth_params)
    
    assert_equal(
      'oauth_consumer_key="anonymous",oauth_nonce="abc",oauth_signature="weu3Z%2Baqn6YUNnSLJmIvUwnCEmo%3D",oauth_signature_method="HMAC-SHA1",oauth_timestamp="1274215474",oauth_token="a",oauth_version="1.0"',
      oauth_string
    )
  end
  
  def test_build_2_legged_oauth_string_should_accept_custom_consumer
    OAuth::Helper.stubs(:generate_key).returns('abc')
    OAuth::Helper.stubs(:generate_timestamp).returns(1274215474)
    
		request_url = "https://mail.google.com/mail/b/user_name@gmail.com/imap/?xoauth_requestor_id=user_name%40gmail.com";
    oauth_params = {
			:two_legged => true,
      :consumer_key => 'c',
      :consumer_secret => 'd',
			:xoauth_requestor_id => 'user_name@gmail.com'
    }
    
    oauth_string = C.new.__send__('build_oauth_string', request_url, oauth_params)
    
    assert_equal(
			'oauth_consumer_key="c",oauth_nonce="abc",oauth_signature="eG6PG7Q%2BPbI%2FNeLLCZ9PvlB%2BUjg%3D",oauth_signature_method="HMAC-SHA1",oauth_timestamp="1274215474",oauth_version="1.0"',
      oauth_string
    )
	end

  def test_build_sasl_client_request
    assert_equal 'GET 1 2', C.new.__send__('build_sasl_client_request', '1', '2')
  end
  
end

class C
  include GmailXoauth::OauthString
end
