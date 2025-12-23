require 'delegate'

begin
  require 'strong_parameters'
rescue LoadError
end

require 'active_support/hash_with_indifferent_access'

module Shoulda
  module Matchers
    module ActionController
      # The `permit` matcher tests that an action in your controller receives a
      # whitelist of parameters using Rails' Strong Parameters feature
      # (specifically that `permit` was called with the correct arguments).
      #
      # Here's an example:
      #
      #     class UsersController < ApplicationController
      #       def create
      #         user = User.create(user_params)
      #         # ...
      #       end
      #
      #       private
      #
      #       def user_params
      #         params.require(:user).permit(
      #           :first_name,
      #           :last_name,
      #           :email,
      #           :password
      #         )
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe UsersController, type: :controller do
      #       it do
      #         params = {
      #           user: {
      #             first_name: 'John',
      #             last_name: 'Doe',
      #             email: 'johndoe@example.com',
      #             password: 'password'
      #           }
      #         }
      #         should permit(:first_name, :last_name, :email, :password).
      #           for(:create, params: params).
      #           on(:user)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class UsersControllerTest < ActionController::TestCase
      #       should "(for POST #create) restrict parameters on :user to first_name, last_name, email, and password" do
      #         params = {
      #           user: {
      #             first_name: 'John',
      #             last_name: 'Doe',
      #             email: 'johndoe@example.com',
      #             password: 'password'
      #           }
      #         }
      #         matcher = permit(:first_name, :last_name, :email, :password).
      #           for(:create, params: params).
      #           on(:user)
      #         assert_accepts matcher, subject
      #       end
      #     end
      #
      # If your action requires query parameters in order to work, then you'll
      # need to supply them:
      #
      #     class UsersController < ApplicationController
      #       def update
      #         user = User.find(params[:id])
      #
      #         if user.update_attributes(user_params)
      #           # ...
      #         else
      #           # ...
      #         end
      #       end
      #
      #       private
      #
      #       def user_params
      #         params.require(:user).permit(
      #           :first_name,
      #           :last_name,
      #           :email,
      #           :password
      #         )
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe UsersController, type: :controller do
      #       before do
      #         create(:user, id: 1)
      #       end
      #
      #       it do
      #         params = {
      #           id: 1,
      #           user: {
      #             first_name: 'Jon',
      #             last_name: 'Doe',
      #             email: 'jondoe@example.com',
      #             password: 'password'
      #           }
      #         }
      #         should permit(:first_name, :last_name, :email, :password).
      #           for(:update, params: params).
      #           on(:user)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class UsersControllerTest < ActionController::TestCase
      #       setup do
      #         create(:user, id: 1)
      #       end
      #
      #       should "(for PATCH #update) restrict parameters on :user to :first_name, :last_name, :email, and :password" do
      #         params = {
      #           id: 1,
      #           user: {
      #             first_name: 'Jon',
      #             last_name: 'Doe',
      #             email: 'jondoe@example.com',
      #             password: 'password'
      #           }
      #         }
      #         matcher = permit(:first_name, :last_name, :email, :password).
      #           for(:update, params: params).
      #           on(:user)
      #         assert_accepts matcher, subject
      #       end
      #     end
      #
      # Finally, if you have an action that isn't one of the seven resourceful
      # actions, then you'll need to provide the HTTP verb that it responds to:
      #
      #     Rails.application.routes.draw do
      #       resources :users do
      #         member do
      #           put :toggle
      #         end
      #       end
      #     end
      #
      #     class UsersController < ApplicationController
      #       def toggle
      #         user = User.find(params[:id])
      #
      #         if user.update_attributes(user_params)
      #           # ...
      #         else
      #           # ...
      #         end
      #       end
      #
      #       private
      #
      #       def user_params
      #         params.require(:user).permit(:activated)
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe UsersController, type: :controller do
      #       before do
      #         create(:user, id: 1)
      #       end
      #
      #       it do
      #         params = { id: 1, user: { activated: true } }
      #         should permit(:activated).
      #           for(:toggle, params: params, verb: :put).
      #           on(:user)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class UsersControllerTest < ActionController::TestCase
      #       setup do
      #         create(:user, id: 1)
      #       end
      #
      #       should "(for PUT #toggle) restrict parameters on :user to :activated" do
      #         params = { id: 1, user: { activated: true } }
      #         matcher = permit(:activated).
      #           for(:toggle, params: params, verb: :put).
      #           on(:user)
      #         assert_accepts matcher, subject
      #       end
      #     end
      #
      # @return [PermitMatcher]
      #
      def permit(*params)
        PermitMatcher.new(params).in_context(self)
      end

      # @private
      class PermitMatcher
        attr_writer :stubbed_params

        def initialize(expected_permitted_parameter_names)
          @expected_permitted_parameter_names =
            expected_permitted_parameter_names
          @action = nil
          @verb = nil
          @request_params = {}
          @subparameter_name = nil
          @parameters_double_registry = CompositeParametersDoubleRegistry.new
        end

        def for(action, options = {})
          @action = action
          @verb = options.fetch(:verb, default_verb)
          @request_params = options.fetch(:params, {})
          self
        end

        def add_params(params)
          request_params.merge!(params)
          self
        end

        def on(subparameter_name)
          @subparameter_name = subparameter_name
          self
        end

        def in_context(context)
          @context = context
          self
        end

        def description
          "(for #{verb.upcase} ##{action}) " + expectation
        end

        def matches?(controller)
          @controller = controller
          ensure_action_and_verb_present!

          parameters_double_registry.register

          Doublespeak.with_doubles_activated do
            params = { params: request_params }

            context.__send__(verb, action, **params)
          end

          unpermitted_parameter_names.empty?
        end

        def failure_message
          "Expected #{verb.upcase} ##{action} to #{expectation},"\
          "\nbut #{reality}."
        end

        def failure_message_when_negated
          "Expected #{verb.upcase} ##{action} not to #{expectation},"\
          "\nbut it did."
        end

        protected

        attr_reader :controller, :double_collections_by_parameter_name, :action,
          :verb, :request_params, :expected_permitted_parameter_names,
          :context, :subparameter_name, :parameters_double_registry

        def expectation
          message = 'restrict parameters '

          if subparameter_name
            message << "on #{subparameter_name.inspect} "
          end

          message << 'to '\
            "#{format_parameter_names(expected_permitted_parameter_names)}"

          message
        end

        def reality
          if actual_permitted_parameter_names.empty?
            'it did not restrict any parameters'
          else
            'the restricted parameters were '\
            "#{format_parameter_names(actual_permitted_parameter_names)}"\
            ' instead'
          end
        end

        def format_parameter_names(parameter_names)
          parameter_names.map(&:inspect).to_sentence
        end

        def actual_permitted_parameter_names
          @_actual_permitted_parameter_names ||= begin
            options =
              if subparameter_name
                { for: subparameter_name }
              else
                {}
              end
            parameters_double_registry.permitted_parameter_names(options)
          end
        end

        def unpermitted_parameter_names
          expected_permitted_parameter_names - actual_permitted_parameter_names
        end

        def ensure_action_and_verb_present!
          if action.blank?
            raise ActionNotDefinedError
          end

          if verb.blank?
            raise VerbNotDefinedError
          end
        end

        def default_verb
          case action
          when :create then :post
          when :update then RailsShim.verb_for_update
          end
        end

        def parameter_names_as_sentence
          expected_permitted_parameter_names.map(&:inspect).to_sentence
        end

        # @private
        class CompositeParametersDoubleRegistry
          def initialize
            @parameters_double_registries = []
          end

          def register
            double_collection = Doublespeak.double_collection_for(
              ::ActionController::Parameters.singleton_class,
            )
            double_collection.register_proxy(:new).to_return do |call|
              params = call.return_value
              parameters_double_registry = ParametersDoubleRegistry.new(params)
              parameters_double_registry.register
              parameters_double_registries << parameters_double_registry
            end
          end

          def permitted_parameter_names(options = {})
            parameters_double_registries.flat_map do |double_registry|
              double_registry.permitted_parameter_names(options)
            end
          end

          protected

          attr_reader :parameters_double_registries
        end

        # @private
        class ParametersDoubleRegistry
          TOP_LEVEL = Object.new

          def self.permitted_parameter_names_within(double_collection)
            double_collection.calls_to(:permit).map(&:args).flatten
          end

          def initialize(params)
            @params = params
            @double_collections_by_parameter_name = {}
          end

          def register
            register_double_for_permit_against(params, TOP_LEVEL)
          end

          def permitted_parameter_names(args = {})
            subparameter_name = args.fetch(:for, TOP_LEVEL)

            if double_collections_by_parameter_name.key?(subparameter_name)
              self.class.permitted_parameter_names_within(
                double_collections_by_parameter_name[subparameter_name],
              )
            else
              []
            end
          end

          protected

          attr_reader :params, :double_collections_by_parameter_name

          private

          def register_double_for_permit_against(params, subparameter_name)
            klass = params.singleton_class

            double_collection = Doublespeak.double_collection_for(klass)
            register_double_for_permit_on(double_collection)
            register_double_for_require_on(double_collection)

            double_collections_by_parameter_name[subparameter_name] =
              double_collection
          end

          def register_double_for_permit_on(double_collection)
            double_collection.register_proxy(:permit)
          end

          def register_double_for_require_on(double_collection)
            double_collection.register_proxy(:require).to_return do |call|
              params = call.return_value
              subparameter_name = call.args.first
              register_double_for_permit_against(params, subparameter_name)
            end
          end
        end

        # @private
        class ActionNotDefinedError < StandardError
          def message
            'You must specify the controller action using the #for method.'
          end
        end

        # @private
        class VerbNotDefinedError < StandardError
          def message
            'You must specify an HTTP verb when using a non-RESTful action.'\
            ' For example: for(:authorize, verb: :post)'
          end
        end
      end
    end
  end
end
