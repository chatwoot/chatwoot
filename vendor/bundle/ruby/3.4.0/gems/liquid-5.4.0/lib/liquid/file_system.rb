# frozen_string_literal: true

module Liquid
  # A Liquid file system is a way to let your templates retrieve other templates for use with the include tag.
  #
  # You can implement subclasses that retrieve templates from the database, from the file system using a different
  # path structure, you can provide them as hard-coded inline strings, or any manner that you see fit.
  #
  # You can add additional instance variables, arguments, or methods as needed.
  #
  # Example:
  #
  #   Liquid::Template.file_system = Liquid::LocalFileSystem.new(template_path)
  #   liquid = Liquid::Template.parse(template)
  #
  # This will parse the template with a LocalFileSystem implementation rooted at 'template_path'.
  class BlankFileSystem
    # Called by Liquid to retrieve a template file
    def read_template_file(_template_path)
      raise FileSystemError, "This liquid context does not allow includes."
    end
  end

  # This implements an abstract file system which retrieves template files named in a manner similar to Rails partials,
  # ie. with the template name prefixed with an underscore. The extension ".liquid" is also added.
  #
  # For security reasons, template paths are only allowed to contain letters, numbers, and underscore.
  #
  # Example:
  #
  #   file_system = Liquid::LocalFileSystem.new("/some/path")
  #
  #   file_system.full_path("mypartial")       # => "/some/path/_mypartial.liquid"
  #   file_system.full_path("dir/mypartial")   # => "/some/path/dir/_mypartial.liquid"
  #
  # Optionally in the second argument you can specify a custom pattern for template filenames.
  # The Kernel::sprintf format specification is used.
  # Default pattern is "_%s.liquid".
  #
  # Example:
  #
  #   file_system = Liquid::LocalFileSystem.new("/some/path", "%s.html")
  #
  #   file_system.full_path("index") # => "/some/path/index.html"
  #
  class LocalFileSystem
    attr_accessor :root

    def initialize(root, pattern = "_%s.liquid")
      @root    = root
      @pattern = pattern
    end

    def read_template_file(template_path)
      full_path = full_path(template_path)
      raise FileSystemError, "No such template '#{template_path}'" unless File.exist?(full_path)

      File.read(full_path)
    end

    def full_path(template_path)
      raise FileSystemError, "Illegal template name '#{template_path}'" unless %r{\A[^./][a-zA-Z0-9_/]+\z}.match?(template_path)

      full_path = if template_path.include?('/')
        File.join(root, File.dirname(template_path), @pattern % File.basename(template_path))
      else
        File.join(root, @pattern % template_path)
      end

      raise FileSystemError, "Illegal template path '#{File.expand_path(full_path)}'" unless File.expand_path(full_path).start_with?(File.expand_path(root))

      full_path
    end
  end
end
