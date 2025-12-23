# frozen_string_literal: true

class SampleResource < ApplicationResource
  uri 'examples/users'
  resource_name 'Users'
  description 'A user resource for demonstration'
  mime_type 'application/json'

  def content
    JSON.generate(User.all.as_json)
  end
end
