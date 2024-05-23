require 'rubocop'

# enforce rubocop custom rules to only be added in the `rubocop` directory
class CustomCopLocation < RuboCop::Cop::Base
  MSG = 'Custom cops should be added in the `rubocop` directory.'.freeze

  def on_send(node)
    return unless node.source.include?('require \'rubocop\'')

    # convert the full path to relative
    full_path = processed_source.file_path
    relative_path = Pathname.new(full_path).relative_path_from(Pathname.new(Dir.pwd)).to_s

    return if relative_path.start_with?('rubocop')

    add_offense(node, message: MSG)
  end
end
