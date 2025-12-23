# frozen_string_literal: true
require_relative 'pipeline'

module Tilt
  # Private internal base class for both Mapping and FinalizedMapping, for the shared methods.
  class BaseMapping
    # Instantiates a new template class based on the file.
    #
    # @raise [RuntimeError] if there is no template class registered for the
    #   file name.
    #
    # @example
    #   mapping.new('index.mt') # => instance of MyEngine::Template
    #
    # @see Tilt::Template.new
    def new(file, line=nil, options={}, &block)
      if template_class = self[file]
        template_class.new(file, line, options, &block)
      else
        fail "No template engine registered for #{File.basename(file)}"
      end
    end

    # Looks up a template class based on file name and/or extension.
    #
    # @example
    #   mapping['views/hello.erb'] # => Tilt::ERBTemplate
    #   mapping['hello.erb']       # => Tilt::ERBTemplate
    #   mapping['erb']             # => Tilt::ERBTemplate
    #
    # @return [template class]
    def [](file)
      _, ext = split(file)
      ext && lookup(ext)
    end

    alias template_for []

    # Looks up a list of template classes based on file name. If the file name
    # has multiple extensions, it will return all template classes matching the
    # extensions from the end.
    #
    # @example
    #   mapping.templates_for('views/index.haml.erb')
    #   # => [Tilt::ERBTemplate, Tilt::HamlTemplate]
    #
    # @return [Array<template class>]
    def templates_for(file)
      templates = []

      while true
        prefix, ext = split(file)
        break unless ext
        templates << lookup(ext)
        file = prefix
      end

      templates
    end

    private

    def split(file)
      pattern = file.to_s.downcase
      full_pattern = pattern.dup

      until registered?(pattern)
        return if pattern.empty?
        pattern = File.basename(pattern)
        pattern.sub!(/\A[^.]*\.?/, '')
      end

      prefix_size = full_pattern.size - pattern.size
      [full_pattern[0,prefix_size-1], pattern]
    end
  end
  private_constant :BaseMapping

  # Tilt::Mapping associates file extensions with template implementations.
  #
  #     mapping = Tilt::Mapping.new
  #     mapping.register(Tilt::RDocTemplate, 'rdoc')
  #     mapping['index.rdoc'] # => Tilt::RDocTemplate
  #     mapping.new('index.rdoc').render
  #
  # You can use {#register} to register a template class by file
  # extension, {#registered?} to see if a file extension is mapped,
  # {#[]} to lookup template classes, and {#new} to instantiate template
  # objects.
  #
  # Mapping also supports *lazy* template implementations. Note that regularly
  # registered template implementations *always* have preference over lazily
  # registered template implementations. You should use {#register} if you
  # depend on a specific template implementation and {#register_lazy} if there
  # are multiple alternatives.
  #
  #     mapping = Tilt::Mapping.new
  #     mapping.register_lazy('RDiscount::Template', 'rdiscount/template', 'md')
  #     mapping['index.md']
  #     # => RDiscount::Template
  #
  # {#register_lazy} takes a class name, a filename, and a list of file
  # extensions. When you try to lookup a template name that matches the
  # file extension, Tilt will automatically try to require the filename and
  # constantize the class name.
  #
  # Unlike {#register}, there can be multiple template implementations
  # registered lazily to the same file extension. Tilt will attempt to load the
  # template implementations in order (registered *last* would be tried first),
  # returning the first which doesn't raise LoadError.
  #
  # If all of the registered template implementations fails, Tilt will raise
  # the exception of the first, since that was the most preferred one.
  #
  #     mapping = Tilt::Mapping.new
  #     mapping.register_lazy('Maruku::Template', 'maruku/template', 'md')
  #     mapping.register_lazy('RDiscount::Template', 'rdiscount/template', 'md')
  #     mapping['index.md']
  #     # => RDiscount::Template
  #
  # In the previous example we say that RDiscount has a *higher priority* than
  # Maruku. Tilt will first try to `require "rdiscount/template"`, falling
  # back to `require "maruku/template"`. If none of these are successful,
  # the first error will be raised.
  class Mapping < BaseMapping
    LOCK = Mutex.new

    # @private
    attr_reader :lazy_map, :template_map

    def initialize
      @template_map = Hash.new
      @lazy_map = Hash.new { |h, k| h[k] = [] }
    end

    # @private
    def initialize_copy(other)
      LOCK.synchronize do
        @template_map = other.template_map.dup
        @lazy_map = other.lazy_map.dup
      end
    end

    # Return a finalized mapping. A finalized mapping will only include
    # support for template libraries already loaded, and will not
    # allow registering new template libraries or lazy loading template
    # libraries not yet loaded. Finalized mappings improve performance
    # by not requiring synchronization and ensure that the mapping will
    # not attempt to load additional files (useful when restricting
    # file system access after template libraries in use are loaded).
    def finalized
      LOCK.synchronize{@lazy_map.dup}.each do |pattern, classes|
        register_defined_classes(LOCK.synchronize{classes.map(&:first)}, pattern)
      end

      # Check if a template class is already present
      FinalizedMapping.new(LOCK.synchronize{@template_map.dup}.freeze)
    end

    # Registers a lazy template implementation by file extension. You
    # can have multiple lazy template implementations defined on the
    # same file extension, in which case the template implementation
    # defined *last* will be attempted loaded *first*.
    #
    # @param class_name [String] Class name of a template class.
    # @param file [String] Filename where the template class is defined.
    # @param extensions [Array<String>] List of extensions.
    # @return [void]
    #
    # @example
    #   mapping.register_lazy 'MyEngine::Template', 'my_engine/template',  'mt'
    #
    #   defined?(MyEngine::Template) # => false
    #   mapping['index.mt'] # => MyEngine::Template
    #   defined?(MyEngine::Template) # => true
    def register_lazy(class_name, file, *extensions)
      # Internal API
      if class_name.is_a?(Symbol)
        Tilt.autoload class_name, file
        class_name = "Tilt::#{class_name}"
      end

      v = [class_name, file].freeze
      extensions.each do |ext|
        LOCK.synchronize{@lazy_map[ext].unshift(v)}
      end
    end

    # Registers a template implementation by file extension. There can only be
    # one template implementation per file extension, and this method will
    # override any existing mapping.
    #
    # @param template_class
    # @param extensions [Array<String>] List of extensions.
    # @return [void]
    # 
    # @example
    #   mapping.register MyEngine::Template, 'mt'
    #   mapping['index.mt'] # => MyEngine::Template
    def register(template_class, *extensions)
      if template_class.respond_to?(:to_str)
        # Support register(ext, template_class) too
        extensions, template_class = [template_class], extensions[0]
      end

      extensions.each do |ext|
        ext = ext.to_s
        LOCK.synchronize do
          @template_map[ext] = template_class
        end
      end
    end

    # Register a new template class using the given extension that
    # represents a pipeline of multiple existing template, where the
    # output from the previous template is used as input to the next
    # template.
    #
    # This will register a template class that processes the input
    # with the *erb* template processor, and takes the output of
    # that and feeds it to the *scss* template processor, returning
    # the output of the *scss* template processor as the result of
    # the pipeline.
    #
    # @param ext [String] Primary extension to register
    # @option :templates [Array<String>] Extensions of templates
    #         to execute in order (defaults to the ext.split('.').reverse)
    # @option :extra_exts [Array<String>] Additional extensions to register
    # @option String [Hash] Options hash for individual template in the
    #         pipeline (key is extension).
    # @return [void]
    #
    # @example
    #   mapping.register_pipeline('scss.erb')
    #   mapping.register_pipeline('scss.erb', 'erb'=>{:outvar=>'@foo'})
    #   mapping.register_pipeline('scsserb', :extra_exts => 'scss.erb',
    #                             :templates=>['erb', 'scss'])
    def register_pipeline(ext, options=EMPTY_HASH)
      templates = options[:templates] || ext.split('.').reverse
      templates = templates.map{|t| [self[t], options[t] || EMPTY_HASH]}

      klass = Class.new(Pipeline)
      klass.send(:const_set, :TEMPLATES, templates)

      register(klass, ext, *Array(options[:extra_exts]))
      klass
    end

    # Unregisters an extension. This removes the both normal registrations
    # and lazy registrations.
    #
    # @param extensions [Array<String>] List of extensions.
    # @return nil
    #
    # @example
    #   mapping.register MyEngine::Template, 'mt'
    #   mapping['index.mt'] # => MyEngine::Template
    #   mapping.unregister('mt')
    #   mapping['index.mt'] # => nil
    def unregister(*extensions)
      extensions.each do |ext|
        ext = ext.to_s
        LOCK.synchronize do
          @template_map.delete(ext)
          @lazy_map.delete(ext)
        end
      end

      nil
    end

    # Checks if a file extension is registered (either eagerly or
    # lazily) in this mapping.
    #
    # @param ext [String] File extension.
    #
    # @example
    #   mapping.registered?('erb')  # => true
    #   mapping.registered?('nope') # => false
    def registered?(ext)
      ext_downcase = ext.downcase
      LOCK.synchronize{@template_map.has_key?(ext_downcase)} or lazy?(ext)
    end

    # Finds the extensions the template class has been registered under.
    # @param [template class] template_class
    def extensions_for(template_class)
      res = []
      LOCK.synchronize{@template_map.to_a}.each do |ext, klass|
        res << ext if template_class == klass
      end
      LOCK.synchronize{@lazy_map.to_a}.each do |ext, choices|
        res << ext if LOCK.synchronize{choices.dup}.any? { |klass, file| template_class.to_s == klass }
      end
      res.uniq!
      res
    end

    private

    def lazy?(ext)
      ext = ext.downcase
      LOCK.synchronize{@lazy_map.has_key?(ext) && !@lazy_map[ext].empty?}
    end

    def lookup(ext)
      LOCK.synchronize{@template_map[ext]} || lazy_load(ext)
    end

    def register_defined_classes(class_names, pattern)
      class_names.each do |class_name|
        template_class = constant_defined?(class_name)
        if template_class
          register(template_class, pattern)
          yield template_class if block_given?
        end
      end
    end

    def lazy_load(pattern)
      choices = LOCK.synchronize{@lazy_map[pattern].dup}

      # Check if a template class is already present
      register_defined_classes(choices.map(&:first), pattern) do |template_class|
        return template_class
      end

      first_failure = nil

      # Load in order
      choices.each do |class_name, file|
        begin
          require file
          # It's safe to eval() here because constant_defined? will
          # raise NameError on invalid constant names
          template_class = eval(class_name)
        rescue LoadError => ex
          first_failure ||= ex
        else
          register(template_class, pattern)
          return template_class
        end
      end

      raise first_failure
    end

    # The proper behavior (in MRI) for autoload? is to
    # return `false` when the constant/file has been
    # explicitly required.
    #
    # However, in JRuby it returns `true` even after it's
    # been required. In that case it turns out that `defined?`
    # returns `"constant"` if it exists and `nil` when it doesn't.
    # This is actually a second bug: `defined?` should resolve
    # autoload (aka. actually try to require the file).
    #
    # We use the second bug in order to resolve the first bug.

    def constant_defined?(name)
      name.split('::').inject(Object) do |scope, n|
        return false if scope.autoload?(n) || !scope.const_defined?(n)
        scope.const_get(n)
      end
    end
  end

  # Private internal class for finalized mappings, which are frozen and
  # cannot be modified.
  class FinalizedMapping < BaseMapping
    # Set the template map to use.  The template map should already
    # be frozen, but this is an internal class, so it does not
    # explicitly check for that.
    def initialize(template_map)
      @template_map = template_map
      freeze
    end

    # Returns receiver, since instances are always frozen.
    def dup
      self
    end

    # Returns receiver, since instances are always frozen.
    def clone(freeze: false)
      self
    end

    # Return whether the given file extension has been registered.
    def registered?(ext)
      @template_map.has_key?(ext.downcase)
    end

    # Returns an aarry of all extensions the template class will
    # be used for.
    def extensions_for(template_class)
      res = []
      @template_map.each do |ext, klass|
        res << ext if template_class == klass
      end
      res.uniq!
      res
    end

    private

    def lookup(ext)
      @template_map[ext]
    end
  end
  private_constant :FinalizedMapping
end
