require 'rubocop'

module RuboCop::Cop::Chatwoot; end

# A `message:` given to `validates` is evaluated once, when the class body runs. `I18n.t` there
# freezes whatever the backend answers at that moment: in production that is before the locale
# files load, so the API answers "Translation missing" forever, and in any locale but the boot
# one the message never follows the request. Pass a lambda, which Rails calls per validation.
class RuboCop::Cop::Chatwoot::EagerValidationMessage < RuboCop::Cop::Base
  MSG = 'Pass `message: ->(*) { I18n.t(...) }`; `I18n.t` here runs once, at class load.'.freeze
  VALIDATION_METHODS = %i[validates validates! validates_with validates_each].to_set.freeze

  def_node_matcher :translated_message?, <<~PATTERN
    (pair (sym :message) (send (const {nil? cbase} :I18n) {:t :translate} ...))
  PATTERN

  def on_send(node)
    return unless node.receiver.nil? && VALIDATION_METHODS.include?(node.method_name)

    node.each_descendant(:pair) do |pair|
      add_offense(pair) if translated_message?(pair)
    end
  end
end
