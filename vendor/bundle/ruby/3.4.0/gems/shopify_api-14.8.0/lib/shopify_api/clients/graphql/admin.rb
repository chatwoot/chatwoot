# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Clients
    module Graphql
      class Admin < Client
        sig { params(session: T.nilable(Auth::Session), api_version: T.nilable(String)).void }
        def initialize(session:, api_version: nil)
          super(session: session, base_path: "/admin/api", api_version: api_version)
        end
      end
    end
  end
end
