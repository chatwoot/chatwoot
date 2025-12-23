require 'forwardable'

module Shoulda
  module Matchers
    module ActionController
      # The `set_session` matcher is used to make assertions about the
      # `session` hash.
      #
      #     class PostsController < ApplicationController
      #       def index
      #         session[:foo] = 'A candy bar'
      #       end
      #
      #       def destroy
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe PostsController, type: :controller do
      #       describe 'GET #index' do
      #         before { get :index }
      #
      #         it { should set_session }
      #       end
      #
      #       describe 'DELETE #destroy' do
      #         before { delete :destroy }
      #
      #         it { should_not set_session }
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostsControllerTest < ActionController::TestCase
      #       context 'GET #index' do
      #         setup { get :index }
      #
      #         should set_session
      #       end
      #
      #       context 'DELETE #destroy' do
      #         setup { delete :destroy }
      #
      #         should_not set_session
      #       end
      #     end
      #
      # #### Qualifiers
      #
      # ##### []
      #
      # Use `[]` to narrow the scope of the matcher to a particular key.
      #
      #     class PostsController < ApplicationController
      #       def index
      #         session[:foo] = 'A candy bar'
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe PostsController, type: :controller do
      #       describe 'GET #index' do
      #         before { get :index }
      #
      #         it { should set_session[:foo] }
      #         it { should_not set_session[:bar] }
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostsControllerTest < ActionController::TestCase
      #       context 'GET #index' do
      #         setup { get :show }
      #
      #         should set_session[:foo]
      #         should_not set_session[:bar]
      #       end
      #     end
      #
      # ##### to
      #
      # Use `to` to assert that some key was set to a particular value, or that
      # some key matches a particular regex.
      #
      #     class PostsController < ApplicationController
      #       def index
      #         session[:foo] = 'A candy bar'
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe PostsController, type: :controller do
      #       describe 'GET #index' do
      #         before { get :index }
      #
      #         it { should set_session.to('A candy bar') }
      #         it { should set_session.to(/bar/) }
      #         it { should set_session[:foo].to('bar') }
      #         it { should_not set_session[:foo].to('something else') }
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostsControllerTest < ActionController::TestCase
      #       context 'GET #index' do
      #         setup { get :show }
      #
      #         should set_session.to('A candy bar')
      #         should set_session.to(/bar/)
      #         should set_session[:foo].to('bar')
      #         should_not set_session[:foo].to('something else')
      #       end
      #     end
      #
      # @return [SetSessionMatcher]
      #
      def set_session
        SetSessionMatcher.new.in_context(self)
      end

      # @private
      class SetSessionMatcher
        extend Forwardable

        def_delegators :underlying_matcher,
          :description,
          :matches?,
          :failure_message,
          :failure_message_when_negated
        alias_method \
          :failure_message_for_should,
          :failure_message
        alias_method \
          :failure_message_for_should_not,
          :failure_message_when_negated

        def initialize
          store = SessionStore.new
          @underlying_matcher = SetSessionOrFlashMatcher.new(store)
        end

        def in_context(context)
          underlying_matcher.in_context(context)
          self
        end

        def [](key)
          underlying_matcher[key]
          self
        end

        def to(expected_value = nil, &block)
          underlying_matcher.to(expected_value, &block)
          self
        end

        protected

        attr_reader :underlying_matcher
      end
    end
  end
end
