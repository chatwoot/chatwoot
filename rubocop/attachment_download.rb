require 'rubocop'

module RuboCop::Cop::Chatwoot; end

class RuboCop::Cop::Chatwoot::AttachmentDownload < RuboCop::Cop::Base
  MSG = 'Avoid calling `.file/.blob.download`; use `blob.open` or streaming IO instead.'.freeze

  def_node_matcher :unsafe_download?, <<~PATTERN
    (send (send _ {:file :blob}) :download ...)
  PATTERN

  def on_send(node)
    return unless unsafe_download?(node)

    add_offense(node.loc.selector, message: MSG)
  end
end
