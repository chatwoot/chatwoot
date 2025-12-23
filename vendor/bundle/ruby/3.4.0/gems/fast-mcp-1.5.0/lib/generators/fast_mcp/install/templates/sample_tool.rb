# frozen_string_literal: true

class SampleTool < ApplicationTool
  description 'Greet a user'

  arguments do
    required(:id).filled(:integer).description('ID of the user to greet')
    optional(:prefix).filled(:string).description('Prefix to add to the greeting')
  end

  def call(id:, prefix: 'Hey')
    user = User.find(id)

    "#{prefix} #{user.first_name} !"
  end
end
