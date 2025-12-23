module Shoulda
  module Matchers
    module ActionController
      # The `respond_with` matcher tests that an action responds with a certain
      # status code.
      #
      # You can specify that the status should be a number:
      #
      #     class PostsController < ApplicationController
      #       def index
      #         render status: 403
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe PostsController, type: :controller do
      #       describe 'GET #index' do
      #         before { get :index }
      #
      #         it { should respond_with(403) }
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostsControllerTest < ActionController::TestCase
      #       context 'GET #index' do
      #         setup { get :index }
      #
      #         should respond_with(403)
      #       end
      #     end
      #
      # You can specify that the status should be within a range of numbers:
      #
      #     class PostsController < ApplicationController
      #       def destroy
      #         render status: 508
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe PostsController, type: :controller do
      #       describe 'DELETE #destroy' do
      #         before { delete :destroy }
      #
      #         it { should respond_with(500..600) }
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostsControllerTest < ActionController::TestCase
      #       context 'DELETE #destroy' do
      #         setup { delete :destroy }
      #
      #         should respond_with(500..600)
      #       end
      #     end
      #
      # Finally, you can specify that the status should be a symbol:
      #
      #     class PostsController < ApplicationController
      #       def show
      #         render status: :locked
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe PostsController, type: :controller do
      #       describe 'GET #show' do
      #         before { get :show }
      #
      #         it { should respond_with(:locked) }
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PostsControllerTest < ActionController::TestCase
      #       context 'GET #show' do
      #         setup { get :show }
      #
      #         should respond_with(:locked)
      #       end
      #     end
      #
      # @return [RespondWithMatcher]
      #
      def respond_with(status)
        RespondWithMatcher.new(status)
      end

      # @private
      class RespondWithMatcher
        def initialize(status)
          @status = symbol_to_status_code(status)
        end

        def matches?(controller)
          @controller = controller
          correct_status_code? || correct_status_code_range?
        end

        def failure_message
          "Expected #{expectation}"
        end

        def failure_message_when_negated
          "Did not expect #{expectation}"
        end

        def description
          "respond with #{@status}"
        end

        protected

        def correct_status_code?
          response_code == @status
        end

        def correct_status_code_range?
          @status.is_a?(Range) &&
            @status.include?(response_code)
        end

        def response_code
          @controller.response.response_code
        end

        def symbol_to_status_code(potential_symbol)
          case potential_symbol
          when :success  then 200
          when :redirect then 300..399
          when :missing  then 404
          when :error    then 500..599
          when Symbol
            ::Rack::Utils::SYMBOL_TO_STATUS_CODE[potential_symbol]
          else
            potential_symbol
          end
        end

        def expectation
          "response to be a #{@status}, but was #{response_code}"
        end
      end
    end
  end
end
