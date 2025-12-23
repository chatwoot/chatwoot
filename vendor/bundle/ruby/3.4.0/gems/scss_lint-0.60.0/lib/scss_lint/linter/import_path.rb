module SCSSLint
  # Checks formatting of the basenames of @imported partials
  class Linter::ImportPath < Linter
    include LinterRegistry

    def visit_import(node)
      # Ignore CSS imports
      return if File.extname(node.imported_filename) == '.css'
      basename = File.basename(node.imported_filename)
      return if underscore_ok?(basename) && extension_ok?(basename)
      add_lint(node, compose_message(node.imported_filename))
    end

  private

    # Checks if the presence or absence of a leading underscore
    # on a string is ok, given config option.
    #
    # @param str [String] the string to check
    # @return [Boolean]
    def underscore_ok?(str)
      underscore_exists = str.start_with?('_')
      config['leading_underscore'] ? underscore_exists : !underscore_exists
    end

    # Checks if the presence or absence of an `scss` filename
    # extension on a string is ok, given config option.
    #
    # @param str [String] the string to check
    # @return [Boolean]
    def extension_ok?(str)
      extension_exists = str.end_with?('.scss')
      config['filename_extension'] ? extension_exists : !extension_exists
    end

    # Composes a helpful lint message based on the original filename
    # and the config options.
    #
    # @param orig_filename [String] the original filename
    # @return [String] the helpful  lint message
    def compose_message(orig_filename)
      orig_basename = File.basename(orig_filename)
      fixed_basename = orig_basename

      if config['leading_underscore']
        fixed_basename = '_' + fixed_basename unless fixed_basename.start_with?('_')
      else
        fixed_basename = fixed_basename.sub(/^_/, '')
      end

      if config['filename_extension']
        fixed_basename += '.scss' unless fixed_basename.end_with?('.scss')
      else
        fixed_basename = fixed_basename.sub(/\.scss$/, '')
      end

      fixed_filename = orig_filename.sub(/(.*)#{Regexp.quote(orig_basename)}/,
                                         "\\1#{fixed_basename}")
      "Imported partial `#{orig_filename}` should be written as `#{fixed_filename}`"
    end
  end
end
