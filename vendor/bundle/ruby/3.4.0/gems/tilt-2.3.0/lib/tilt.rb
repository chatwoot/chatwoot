# frozen_string_literal: true
require_relative 'tilt/mapping'
require_relative 'tilt/template'

# Namespace for Tilt. This module is not intended to be included anywhere.
module Tilt
  # Current version.
  VERSION = '2.3.0'

  EMPTY_HASH = {}.freeze
  private_constant :EMPTY_HASH

  @default_mapping = Mapping.new

  # Replace the default mapping with a finalized version of the default
  # mapping. This can be done to improve performance after the template
  # libraries you desire to use have already been loaded.  Once this is
  # is called, all attempts to modify the default mapping will fail.
  # This also freezes Tilt itself.
  def self.finalize!
    return self if @default_mapping.is_a?(FinalizedMapping)

    class << self
      prepend(Module.new do
        def lazy_map(*)
          raise "Tilt.#{__callee__} not supported after Tilt.finalize! has been called"
        end
        alias register lazy_map
        alias register_lazy lazy_map
        alias register_pipeline lazy_map
        alias prefer lazy_map
      end)
    end

    @default_mapping = @default_mapping.finalized

    freeze
  end

  # @private
  def self.lazy_map
    @default_mapping.lazy_map
  end

  # @see Tilt::Mapping#register
  def self.register(template_class, *extensions)
    @default_mapping.register(template_class, *extensions)
  end

  # @see Tilt::Mapping#register_lazy
  def self.register_lazy(class_name, file, *extensions)
    @default_mapping.register_lazy(class_name, file, *extensions)
  end

  # @see Tilt::Mapping#register_pipeline
  def self.register_pipeline(ext, options=EMPTY_HASH)
    @default_mapping.register_pipeline(ext, options)
  end

  # @see Tilt::Mapping#registered?
  def self.registered?(ext)
    @default_mapping.registered?(ext)
  end

  # @see Tilt::Mapping#new
  def self.new(file, line=nil, options=nil, &block)
    @default_mapping.new(file, line, options, &block)
  end

  # @see Tilt::Mapping#[]
  def self.[](file)
    @default_mapping[file]
  end

  # @see Tilt::Mapping#template_for
  def self.template_for(file)
    @default_mapping.template_for(file)
  end

  # @see Tilt::Mapping#templates_for
  def self.templates_for(file)
    @default_mapping.templates_for(file)
  end

  class << self
    # @return [Tilt::Mapping] the main mapping object
    attr_reader :default_mapping

    # Alias register as prefer for Tilt 1.x compatibility.
    alias prefer register
  end

  # Extremely simple template cache implementation. Calling applications
  # create a Tilt::Cache instance and use #fetch with any set of hashable
  # arguments (such as those to Tilt.new):
  #
  #     cache = Tilt::Cache.new
  #     cache.fetch(path, line, options) { Tilt.new(path, line, options) }
  #
  # Subsequent invocations return the already loaded template object.
  #
  # @note
  #   Tilt::Cache is a thin wrapper around Hash.  It has the following
  #   limitations:
  #   * Not thread-safe.
  #   * Size is unbounded.
  #   * Keys are not copied defensively, and should not be modified after
  #     being passed to #fetch.  More specifically, the values returned by
  #     key#hash and key#eql? should not change.
  #   If this is too limiting for you, use a different cache implementation.
  class Cache
    def initialize
      @cache = {}
    end

    # Caches a value for key, or returns the previously cached value.
    # If a value has been previously cached for key then it is
    # returned. Otherwise, block is yielded to and its return value
    # which may be nil, is cached under key and returned.
    # @yield
    # @yieldreturn the value to cache for key
    def fetch(*key)
      @cache.fetch(key) do
        @cache[key] = yield
      end
    end

    # Clears the cache.
    def clear
      @cache = {}
    end
  end
  # :nocov:
  # TILT3: Remove Tilt::Cache
  deprecate_constant :Cache if respond_to?(:deprecate_constant, true)
  # :nocov:

  # Template Implementations ================================================

  # ERB
  register_lazy :ERBTemplate,    'tilt/erb',    'erb', 'rhtml'
  register_lazy :ErubisTemplate, 'tilt/erubis', 'erb', 'rhtml', 'erubis'
  register_lazy :ErubiTemplate,  'tilt/erubi',  'erb', 'rhtml', 'erubi'

  # Markdown
  register_lazy :MarukuTemplate,       'tilt/maruku',       'markdown', 'mkd', 'md'
  register_lazy :KramdownTemplate,     'tilt/kramdown',     'markdown', 'mkd', 'md'
  register_lazy :RDiscountTemplate,    'tilt/rdiscount',    'markdown', 'mkd', 'md'
  register_lazy :RedcarpetTemplate,    'tilt/redcarpet',    'markdown', 'mkd', 'md'
  register_lazy :CommonMarkerTemplate, 'tilt/commonmarker', 'markdown', 'mkd', 'md'
  register_lazy :PandocTemplate,       'tilt/pandoc',       'markdown', 'mkd', 'md'

  # Rest (sorted by name)
  register_lazy :AsciidoctorTemplate,  'tilt/asciidoc',  'ad', 'adoc', 'asciidoc'
  register_lazy :BabelTemplate,        'tilt/babel',     'es6', 'babel', 'jsx'
  register_lazy :BuilderTemplate,      'tilt/builder',   'builder'
  register_lazy :CSVTemplate,          'tilt/csv',       'rcsv'
  register_lazy :CoffeeScriptTemplate, 'tilt/coffee',    'coffee'
  register_lazy :CoffeeScriptLiterateTemplate, 'tilt/coffee', 'litcoffee'
  register_lazy :CreoleTemplate,       'tilt/creole',    'wiki', 'creole'
  register_lazy :EtanniTemplate,       'tilt/etanni',    'etn', 'etanni'
  register_lazy :HamlTemplate,         'tilt/haml',      'haml'
  register_lazy :LiquidTemplate,       'tilt/liquid',    'liquid'
  register_lazy :LiveScriptTemplate,   'tilt/livescript','ls', 'livescript'
  register_lazy :MarkabyTemplate,      'tilt/markaby',   'mab'
  register_lazy :NokogiriTemplate,     'tilt/nokogiri',  'nokogiri'
  register_lazy :PlainTemplate,        'tilt/plain',     'html'
  register_lazy :PrawnTemplate,        'tilt/prawn',     'prawn'
  register_lazy :RDocTemplate,         'tilt/rdoc',      'rdoc'
  register_lazy :RadiusTemplate,       'tilt/radius',    'radius'
  register_lazy :RedClothTemplate,     'tilt/redcloth',  'textile'
  register_lazy :RstPandocTemplate,    'tilt/rst-pandoc', 'rst'
  register_lazy :SassTemplate,         'tilt/sass',      'sass'
  register_lazy :ScssTemplate,         'tilt/sass',      'scss'
  register_lazy :SlimTemplate,         'tilt/slim',      'slim'
  register_lazy :StringTemplate,       'tilt/string',    'str'
  register_lazy :TypeScriptTemplate,   'tilt/typescript', 'ts', 'tsx'
  register_lazy :WikiClothTemplate,    'tilt/wikicloth', 'wiki', 'mediawiki', 'mw'
  register_lazy :YajlTemplate,         'tilt/yajl',      'yajl'

  # TILT3: Remove
  # Deprecated lazy loading of external template engines
  register_lazy 'Tilt::HandlebarsTemplate',  'tilt/_handlebars', 'handlebars', 'hbs'
  register_lazy 'Tilt::OrgTemplate',         'tilt/_org',        'org'
  register_lazy 'Tilt::OrgTemplate',         'tilt/_emacs_org',  'org'
  register_lazy 'Tilt::JbuilderTemplate',    'tilt/_jbuilder',   'jbuilder'
end
