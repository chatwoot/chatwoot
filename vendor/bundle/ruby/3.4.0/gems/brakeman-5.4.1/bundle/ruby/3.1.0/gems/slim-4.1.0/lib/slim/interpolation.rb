module Slim
  # Perform interpolation of #{var_name} in the
  # expressions `[:slim, :interpolate, string]`.
  #
  # @api private
  class Interpolation < Filter
    # Handle interpolate expression `[:slim, :interpolate, string]`
    #
    # @param [String] string Static interpolate
    # @return [Array] Compiled temple expression
    def on_slim_interpolate(string)
      # Interpolate variables in text (#{variable}).
      # Split the text into multiple dynamic and static parts.
      block = [:multi]
      begin
        case string
        when /\A\\#\{/
          # Escaped interpolation
          block << [:static, '#{']
          string = $'
        when /\A#\{((?>[^{}]|(\{(?>[^{}]|\g<1>)*\}))*)\}/
          # Interpolation
          string, code = $', $1
          escape = code !~ /\A\{.*\}\Z/
          block << [:slim, :output, escape, escape ? code : code[1..-2], [:multi]]
        when /\A([#\\]?[^#\\]*([#\\][^\\#\{][^#\\]*)*)/
          # Static text
          block << [:static, $&]
          string = $'
        end
      end until string.empty?
      block
    end
  end
end
