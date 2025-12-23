require 'active_record'
require 'active_record/version'
require 'active_support/core_ext/module'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect "acts-as-taggable-on" => "ActsAsTaggableOn"
loader.setup

begin
  require 'rails/engine'
  require 'acts-as-taggable-on/engine'
  rescue LoadError
end

require 'digest/sha1'

module ActsAsTaggableOn
  class DuplicateTagError < StandardError
  end

  def self.setup
    @configuration ||= Configuration.new
    yield @configuration if block_given?
  end

  def self.method_missing(method_name, *args, &block)
    @configuration.respond_to?(method_name) ?
        @configuration.send(method_name, *args, &block) : super
  end

  def self.respond_to?(method_name, include_private=false)
    @configuration.respond_to? method_name
  end

  def self.glue
    setting = @configuration.delimiter
    delimiter = setting.kind_of?(Array) ? setting[0] : setting
    delimiter.end_with?(' ') ? delimiter : "#{delimiter} "
  end

  class Configuration
    attr_accessor :force_lowercase, :force_parameterize,
                  :remove_unused_tags, :default_parser,
                  :tags_counter, :tags_table,
                  :taggings_table
    attr_reader :delimiter, :strict_case_match, :base_class

    def initialize
      @delimiter = ','
      @force_lowercase = false
      @force_parameterize = false
      @strict_case_match = false
      @remove_unused_tags = false
      @tags_counter = true
      @default_parser = DefaultParser
      @force_binary_collation = false
      @tags_table = :tags
      @taggings_table = :taggings
      @base_class = '::ActiveRecord::Base'
    end

    def strict_case_match=(force_cs)
      @strict_case_match = force_cs unless @force_binary_collation
    end

    def delimiter=(string)
      ActiveRecord::Base.logger.warn <<WARNING
ActsAsTaggableOn.delimiter is deprecated \
and will be removed from v4.0+, use  \
a ActsAsTaggableOn.default_parser instead
WARNING
      @delimiter = string
    end

    def force_binary_collation=(force_bin)
      if Utils.using_mysql?
        if force_bin
          Configuration.apply_binary_collation(true)
          @force_binary_collation = true
          @strict_case_match = true
        else
          Configuration.apply_binary_collation(false)
          @force_binary_collation = false
        end
      end
    end

    def self.apply_binary_collation(bincoll)
      if Utils.using_mysql?
        coll = 'utf8_general_ci'
        coll = 'utf8_bin' if bincoll
        begin
          ActiveRecord::Migration.execute("ALTER TABLE #{Tag.table_name} MODIFY name varchar(255) CHARACTER SET utf8 COLLATE #{coll};")
        rescue Exception => e
          puts "Trapping #{e.class}: collation parameter ignored while migrating for the first time."
        end
      end
    end

    def base_class=(base_class)
      raise "base_class must be a String" unless base_class.is_a?(String)
      @base_class = base_class
    end

  end

  setup
end

ActiveSupport.on_load(:active_record) do
  extend ActsAsTaggableOn::Taggable
  include ActsAsTaggableOn::Tagger
end

ActiveSupport.on_load(:action_view) do
  include ActsAsTaggableOn::TagsHelper
end
