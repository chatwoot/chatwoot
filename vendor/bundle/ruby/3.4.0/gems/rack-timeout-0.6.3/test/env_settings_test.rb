require 'test_helper'

class EnvSettingsTest < RackTimeoutTest

  def test_service_timeout
    with_env(RACK_TIMEOUT_SERVICE_TIMEOUT: 1) do
      assert_raises(Rack::Timeout::RequestTimeoutError) do
        get "/sleep"
      end
    end
  end

  def test_zero_wait_timeout
    with_env(RACK_TIMEOUT_WAIT_TIMEOUT: 0) do
      get "/", "", 'HTTP_X_REQUEST_START' => time_in_msec(Time.now - 100)
      assert last_response.ok?
    end
  end

  def test_term
    with_env(RACK_TIMEOUT_TERM_ON_TIMEOUT: 1) do
      assert_raises(SignalException) do
        get "/sleep"
      end
    end
  end
end
