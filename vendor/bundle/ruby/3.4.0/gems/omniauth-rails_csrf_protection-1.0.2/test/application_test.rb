require "test_helper"

class ApplicationTest < Minitest::Test
  include Rack::Test::Methods

  def test_request_phrase_not_accessible_via_get
    get "/auth/developer"

    assert last_response.not_found?
  end

  def test_request_phrase_without_token_via_post
    post "/auth/developer"
    follow_redirect!

    assert last_response.not_found?
  end

  def test_request_phrase_with_bad_token_via_post
    post "/auth/developer", authenticity_token: "BAD_TOKEN"
    follow_redirect!

    assert last_response.not_found?
  end

  def test_request_phrase_with_correct_token_via_post
    post "/auth/developer", authenticity_token: authenticity_token

    assert last_response.ok?
  end

  private

    def app
      Rails.application
    end

    def authenticity_token
      get "/token"
      last_response.body
    end
end
