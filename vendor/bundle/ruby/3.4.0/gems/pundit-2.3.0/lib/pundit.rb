# frozen_string_literal: true

require "pundit/version"
require "pundit/policy_finder"
require "active_support/concern"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/module/introspection"
require "active_support/dependencies/autoload"
require "pundit/authorization"

# @api private
# To avoid name clashes with common Error naming when mixing in Pundit,
# keep it here with compact class style definition.
class Pundit::Error < StandardError; end # rubocop:disable Style/ClassAndModuleChildren

# @api public
module Pundit
  SUFFIX = "Policy"

  # @api private
  module Generators; end

  # Error that will be raised when authorization has failed
  class NotAuthorizedError < Error
    attr_reader :query, :record, :policy

    def initialize(options = {})
      if options.is_a? String
        message = options
      else
        @query  = options[:query]
        @record = options[:record]
        @policy = options[:policy]

        message = options.fetch(:message) { "not allowed to #{query} this #{record.class}" }
      end

      super(message)
    end
  end

  # Error that will be raised if a policy or policy scope constructor is not called correctly.
  class InvalidConstructorError < Error; end

  # Error that will be raised if a controller action has not called the
  # `authorize` or `skip_authorization` methods.
  class AuthorizationNotPerformedError < Error; end

  # Error that will be raised if a controller action has not called the
  # `policy_scope` or `skip_policy_scope` methods.
  class PolicyScopingNotPerformedError < AuthorizationNotPerformedError; end

  # Error that will be raised if a policy or policy scope is not defined.
  class NotDefinedError < Error; end

  def self.included(base)
    ActiveSupport::Deprecation.warn <<~WARNING
      'include Pundit' is deprecated. Please use 'include Pundit::Authorization' instead.
    WARNING
    base.include Authorization
  end

  class << self
    # Retrieves the policy for the given record, initializing it with the
    # record and user and finally throwing an error if the user is not
    # authorized to perform the given action.
    #
    # @param user [Object] the user that initiated the action
    # @param possibly_namespaced_record [Object, Array] the object we're checking permissions of
    # @param query [Symbol, String] the predicate method to check on the policy (e.g. `:show?`)
    # @param policy_class [Class] the policy class we want to force use of
    # @param cache [#[], #[]=] a Hash-like object to cache the found policy instance in
    # @raise [NotAuthorizedError] if the given query method returned false
    # @return [Object] Always returns the passed object record
    def authorize(user, possibly_namespaced_record, query, policy_class: nil, cache: {})
      record = pundit_model(possibly_namespaced_record)
      policy = if policy_class
        policy_class.new(user, record)
      else
        cache[possibly_namespaced_record] ||= policy!(user, possibly_namespaced_record)
      end

      raise NotAuthorizedError, query: query, record: record, policy: policy unless policy.public_send(query)

      record
    end

    # Retrieves the policy scope for the given record.
    #
    # @see https://github.com/varvet/pundit#scopes
    # @param user [Object] the user that initiated the action
    # @param scope [Object] the object we're retrieving the policy scope for
    # @raise [InvalidConstructorError] if the policy constructor called incorrectly
    # @return [Scope{#resolve}, nil] instance of scope class which can resolve to a scope
    def policy_scope(user, scope)
      policy_scope_class = PolicyFinder.new(scope).scope
      return unless policy_scope_class

      begin
        policy_scope = policy_scope_class.new(user, pundit_model(scope))
      rescue ArgumentError
        raise InvalidConstructorError, "Invalid #<#{policy_scope_class}> constructor is called"
      end

      policy_scope.resolve
    end

    # Retrieves the policy scope for the given record.
    #
    # @see https://github.com/varvet/pundit#scopes
    # @param user [Object] the user that initiated the action
    # @param scope [Object] the object we're retrieving the policy scope for
    # @raise [NotDefinedError] if the policy scope cannot be found
    # @raise [InvalidConstructorError] if the policy constructor called incorrectly
    # @return [Scope{#resolve}] instance of scope class which can resolve to a scope
    def policy_scope!(user, scope)
      policy_scope_class = PolicyFinder.new(scope).scope!
      return unless policy_scope_class

      begin
        policy_scope = policy_scope_class.new(user, pundit_model(scope))
      rescue ArgumentError
        raise InvalidConstructorError, "Invalid #<#{policy_scope_class}> constructor is called"
      end

      policy_scope.resolve
    end

    # Retrieves the policy for the given record.
    #
    # @see https://github.com/varvet/pundit#policies
    # @param user [Object] the user that initiated the action
    # @param record [Object] the object we're retrieving the policy for
    # @raise [InvalidConstructorError] if the policy constructor called incorrectly
    # @return [Object, nil] instance of policy class with query methods
    def policy(user, record)
      policy = PolicyFinder.new(record).policy
      policy&.new(user, pundit_model(record))
    rescue ArgumentError
      raise InvalidConstructorError, "Invalid #<#{policy}> constructor is called"
    end

    # Retrieves the policy for the given record.
    #
    # @see https://github.com/varvet/pundit#policies
    # @param user [Object] the user that initiated the action
    # @param record [Object] the object we're retrieving the policy for
    # @raise [NotDefinedError] if the policy cannot be found
    # @raise [InvalidConstructorError] if the policy constructor called incorrectly
    # @return [Object] instance of policy class with query methods
    def policy!(user, record)
      policy = PolicyFinder.new(record).policy!
      policy.new(user, pundit_model(record))
    rescue ArgumentError
      raise InvalidConstructorError, "Invalid #<#{policy}> constructor is called"
    end

    private

    def pundit_model(record)
      record.is_a?(Array) ? record.last : record
    end
  end

  # @api private
  module Helper
    def policy_scope(scope)
      pundit_policy_scope(scope)
    end
  end
end
