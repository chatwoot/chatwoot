# encoding: utf-8
# frozen_string_literal: true

require 'sprockets/version'
require 'sprockets/cache'
require 'sprockets/environment'
require 'sprockets/errors'
require 'sprockets/manifest'

module Sprockets
  require 'sprockets/processor_utils'
  extend ProcessorUtils

  # Extend Sprockets module to provide global registry
  require 'sprockets/configuration'
  require 'sprockets/context'
  require 'digest/sha2'
  extend Configuration

  self.config = {
    bundle_processors: Hash.new { |h, k| [].freeze }.freeze,
    bundle_reducers: Hash.new { |h, k| {}.freeze }.freeze,
    compressors: Hash.new { |h, k| {}.freeze }.freeze,
    dependencies: Set.new.freeze,
    dependency_resolvers: {}.freeze,
    digest_class: Digest::SHA256,
    mime_exts: {}.freeze,
    mime_types: {}.freeze,
    paths: [].freeze,
    pipelines: {}.freeze,
    pipeline_exts: {}.freeze,
    postprocessors: Hash.new { |h, k| [].freeze }.freeze,
    preprocessors: Hash.new { |h, k| [].freeze }.freeze,
    registered_transformers: [].freeze,
    root: __dir__.dup.freeze,
    transformers: Hash.new { |h, k| {}.freeze }.freeze,
    exporters: Hash.new { |h, k| Set.new.freeze }.freeze,
    version: "",
    gzip_enabled: true,
    export_concurrent: true
  }.freeze

  @context_class = Context

  require 'logger'
  @logger = Logger.new($stderr)
  @logger.level = Logger::FATAL

  # Common asset text types
  register_mime_type 'application/javascript', extensions: ['.js'], charset: :unicode
  register_mime_type 'application/json', extensions: ['.json'], charset: :unicode
  register_mime_type 'application/ruby', extensions: ['.rb']
  register_mime_type 'application/xml', extensions: ['.xml']
  register_mime_type 'application/manifest+json', extensions: ['.webmanifest']
  register_mime_type 'text/css', extensions: ['.css'], charset: :css
  register_mime_type 'text/html', extensions: ['.html', '.htm'], charset: :html
  register_mime_type 'text/plain', extensions: ['.txt', '.text']
  register_mime_type 'text/yaml', extensions: ['.yml', '.yaml'], charset: :unicode

  # Common image types
  register_mime_type 'image/x-icon', extensions: ['.ico']
  register_mime_type 'image/bmp', extensions: ['.bmp']
  register_mime_type 'image/gif', extensions: ['.gif']
  register_mime_type 'image/webp', extensions: ['.webp']
  register_mime_type 'image/png', extensions: ['.png']
  register_mime_type 'image/jpeg', extensions: ['.jpg', '.jpeg']
  register_mime_type 'image/tiff', extensions: ['.tiff', '.tif']
  register_mime_type 'image/svg+xml', extensions: ['.svg']

  # Common audio/video types
  register_mime_type 'video/webm', extensions: ['.webm']
  register_mime_type 'audio/basic', extensions: ['.snd', '.au']
  register_mime_type 'audio/aiff', extensions: ['.aiff']
  register_mime_type 'audio/mpeg', extensions: ['.mp3', '.mp2', '.m2a', '.m3a']
  register_mime_type 'application/ogg', extensions: ['.ogx']
  register_mime_type 'audio/ogg', extensions: ['.ogg', '.oga']
  register_mime_type 'audio/midi', extensions: ['.midi', '.mid']
  register_mime_type 'video/avi', extensions: ['.avi']
  register_mime_type 'audio/wave', extensions: ['.wav', '.wave']
  register_mime_type 'video/mp4', extensions: ['.mp4', '.m4v']
  register_mime_type 'audio/aac', extensions: ['.aac']
  register_mime_type 'audio/mp4', extensions: ['.m4a']
  register_mime_type 'audio/flac', extensions: ['.flac']

  # Common font types
  register_mime_type 'application/vnd.ms-fontobject', extensions: ['.eot']
  register_mime_type 'application/x-font-opentype', extensions: ['.otf']
  register_mime_type 'application/x-font-ttf', extensions: ['.ttf']
  register_mime_type 'application/font-woff', extensions: ['.woff']
  register_mime_type 'application/font-woff2', extensions: ['.woff2']

  require 'sprockets/source_map_processor'
  register_mime_type 'application/js-sourcemap+json', extensions: ['.js.map'], charset: :unicode
  register_mime_type 'application/css-sourcemap+json', extensions: ['.css.map'], charset: :unicode
  register_transformer 'application/javascript', 'application/js-sourcemap+json', SourceMapProcessor
  register_transformer 'text/css', 'application/css-sourcemap+json', SourceMapProcessor

  register_pipeline :source do |env|
    []
  end

  register_pipeline :self do |env, type, file_type|
    env.self_processors_for(type, file_type)
  end

  register_pipeline :default do |env, type, file_type|
    env.default_processors_for(type, file_type)
  end

  require 'sprockets/add_source_map_comment_to_asset_processor'
  register_pipeline :debug do
    [AddSourceMapCommentToAssetProcessor]
  end

  require 'sprockets/directive_processor'
  register_preprocessor 'text/css', DirectiveProcessor.new(comments: ["//", ["/*", "*/"]])
  register_preprocessor 'application/javascript', DirectiveProcessor.new(comments: ["//", ["/*", "*/"]])

  require 'sprockets/bundle'
  register_bundle_processor 'application/javascript', Bundle
  register_bundle_processor 'text/css', Bundle

  register_bundle_metadata_reducer '*/*', :data, proc { +"" }, :concat
  register_bundle_metadata_reducer 'application/javascript', :data, proc { +"" }, Utils.method(:concat_javascript_sources)
  register_bundle_metadata_reducer '*/*', :links, :+
  register_bundle_metadata_reducer '*/*', :sources, proc { [] }, :+

  require 'sprockets/closure_compressor'
  require 'sprockets/sass_compressor'
  require 'sprockets/sassc_compressor'
  require 'sprockets/jsminc_compressor'
  require 'sprockets/uglifier_compressor'
  require 'sprockets/yui_compressor'
  register_compressor 'text/css', :sass, SassCompressor
  register_compressor 'text/css', :sassc, SasscCompressor
  register_compressor 'text/css', :scss, SassCompressor
  register_compressor 'text/css', :scssc, SasscCompressor
  register_compressor 'text/css', :yui, YUICompressor
  register_compressor 'application/javascript', :closure, ClosureCompressor
  register_compressor 'application/javascript', :jsmin, JSMincCompressor
  register_compressor 'application/javascript', :jsminc, JSMincCompressor
  register_compressor 'application/javascript', :uglifier, UglifierCompressor
  register_compressor 'application/javascript', :uglify, UglifierCompressor
  register_compressor 'application/javascript', :yui, YUICompressor

  # Babel, TheFuture™ is now
  require 'sprockets/babel_processor'
  register_mime_type 'application/ecmascript-6', extensions: ['.es6'], charset: :unicode
  register_transformer 'application/ecmascript-6', 'application/javascript', BabelProcessor
  register_preprocessor 'application/ecmascript-6', DirectiveProcessor.new(comments: ["//", ["/*", "*/"]])

  # Mmm, CoffeeScript
  require 'sprockets/coffee_script_processor'
  register_mime_type 'text/coffeescript', extensions: ['.coffee', '.js.coffee']
  register_transformer 'text/coffeescript', 'application/javascript', CoffeeScriptProcessor
  register_preprocessor 'text/coffeescript', DirectiveProcessor.new(comments: ["#", ["###", "###"]])

  # JST processors
  require 'sprockets/eco_processor'
  require 'sprockets/ejs_processor'
  require 'sprockets/jst_processor'
  register_mime_type 'text/eco', extensions: ['.eco', '.jst.eco']
  register_mime_type 'text/ejs', extensions: ['.ejs', '.jst.ejs']
  register_transformer 'text/eco', 'application/javascript+function', EcoProcessor
  register_transformer 'text/ejs', 'application/javascript+function', EjsProcessor
  register_transformer 'application/javascript+function', 'application/javascript', JstProcessor

  # CSS processors
  require 'sprockets/sassc_processor'
  register_mime_type 'text/sass', extensions: ['.sass', '.css.sass']
  register_mime_type 'text/scss', extensions: ['.scss', '.css.scss']
  register_transformer 'text/sass', 'text/css', SasscProcessor
  register_transformer 'text/scss', 'text/css', ScsscProcessor
  register_preprocessor 'text/sass', DirectiveProcessor.new(comments: ["//", ["/*", "*/"]])
  register_preprocessor 'text/scss', DirectiveProcessor.new(comments: ["//", ["/*", "*/"]])
  register_bundle_metadata_reducer 'text/css', :sass_dependencies, Set.new, :+

  # ERB
  require 'sprockets/erb_processor'
  register_transformer_suffix(%w(
    application/ecmascript-6
    application/javascript
    application/json
    application/manifest+json
    application/xml
    text/coffeescript
    text/css
    text/html
    text/plain
    text/sass
    text/scss
    text/yaml
    text/eco
    text/ejs
  ), 'application/\2+ruby', '.erb', ERBProcessor)

  register_mime_type 'application/html+ruby', extensions: ['.html.erb', '.erb', '.rhtml'], charset: :html
  register_mime_type 'application/xml+ruby', extensions: ['.xml.erb', '.rxml']

  require 'sprockets/exporters/file_exporter'
  require 'sprockets/exporters/zlib_exporter'
  require 'sprockets/exporters/zopfli_exporter'
  register_exporter '*/*', Exporters::FileExporter
  register_exporter '*/*', Exporters::ZlibExporter

  register_dependency_resolver 'environment-version' do |env|
    env.version
  end
  register_dependency_resolver 'environment-paths' do |env|
    env.paths.map {|path| env.compress_from_root(path) }
  end
  register_dependency_resolver 'file-digest' do |env, str|
    env.file_digest(env.parse_file_digest_uri(str))
  end
  register_dependency_resolver 'processors' do |env, str|
    env.resolve_processors_cache_key_uri(str)
  end
  register_dependency_resolver 'env' do |env, str|
    _, var = str.split(':', 2)
    ENV[var]
  end

  depend_on 'environment-version'
  depend_on 'environment-paths'

  require 'sprockets/preprocessors/default_source_map'
  register_preprocessor 'text/css',               Preprocessors::DefaultSourceMap.new
  register_preprocessor 'application/javascript', Preprocessors::DefaultSourceMap.new

  register_bundle_metadata_reducer 'text/css',               :map, proc { |input| { "version" => 3, "file" => PathUtils.split_subpath(input[:load_path], input[:filename]), "sections" => [] } }, SourceMapUtils.method(:concat_source_maps)
  register_bundle_metadata_reducer 'application/javascript', :map, proc { |input| { "version" => 3, "file" => PathUtils.split_subpath(input[:load_path], input[:filename]), "sections" => [] } }, SourceMapUtils.method(:concat_source_maps)
end
