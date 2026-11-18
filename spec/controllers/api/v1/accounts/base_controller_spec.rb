require 'rails_helper'

RSpec.describe Api::V1::Accounts::BaseController do
  describe 'callback ordering' do
    # Re-declaring `before_action :current_account` in a subclass makes Rails
    # de-duplicate the callback and move it to the end of the chain, so
    # `validate_token_api_access` runs while `Current.account` is still nil and
    # every request authenticated with the `api_access_token` header fails
    # with a 500.
    #
    # Enterprise controllers that break the order upstream, which the fork does not patch. Each one
    # must still break it: once upstream fixes it, the example fails and the entry goes.
    known_upstream_defects = {
      'Api::V1::Accounts::Captain::FaqSuggestionsController' => 'fazer-ai/chatwoot#1005'
    }

    it 'runs current_account before validate_token_api_access in every descendant' do
      Rails.application.eager_load!
      defects_seen = []

      ([described_class] + described_class.descendants).each do |controller|
        filters = controller._process_action_callbacks.select { |callback| callback.kind == :before }.map(&:filter)
        validate_index = filters.index(:validate_token_api_access)
        next if validate_index.nil?

        if known_upstream_defects.key?(controller.name)
          defects_seen << controller.name
          expect(filters.index(:current_account)).to be > validate_index,
                                                     "#{controller.name} is fixed upstream: drop it (#{known_upstream_defects[controller.name]})"
          next
        end

        expect(filters.index(:current_account)).to be < validate_index,
                                                   "#{controller.name} runs validate_token_api_access before current_account"
      end

      # An entry whose controller is gone, or no longer runs the check, is stale too.
      expect(defects_seen).to match_array(known_upstream_defects.keys) if ChatwootApp.enterprise?
    end
  end
end
