# frozen_string_literal: true

require 'fileutils'
require 'yard'

# Class for generating documentation of all cops departments
# @api private
class CopsDocumentationGenerator # rubocop:disable Metrics/ClassLength
  include ::RuboCop::Cop::Documentation
  CopData = Struct.new(
    :cop, :description, :example_objects, :safety_objects, :see_objects, :config, keyword_init: true
  )

  STRUCTURE = {
    name:                  ->(data) { cop_header(data.cop) },
    required_ruby_version: ->(data) { required_ruby_version(data.cop) },
    properties:            ->(data) { properties(data.cop) },
    description:           ->(data) { "#{data.description}\n" },
    safety:                ->(data) { safety_object(data.safety_objects, data.cop) },
    examples:              ->(data) { examples(data.example_objects, data.cop) },
    configuration:         ->(data) { configurations(data.cop.department, data.cop, data.config) },
    references:            ->(data) { references(data.cop, data.see_objects) }
  }.freeze

  # This class will only generate documentation for cops that belong to one of
  # the departments given in the `departments` array. E.g. if we only wanted
  # documentation for Lint cops:
  #
  #   CopsDocumentationGenerator.new(departments: ['Lint']).call
  #
  # For plugin extensions, specify `:plugin_name` keyword as follows:
  #
  #   CopsDocumentationGenerator.new(
  #     departments: ['Performance'], plugin_name: 'rubocop-performance'
  #   ).call
  #
  # You can append additional information:
  #
  #   callback = ->(data) { required_rails_version(data.cop) }
  #   CopsDocumentationGenerator.new(extra_info: { ruby_version: callback }).call
  #
  # This will insert the string returned from the lambda _after_ the section from RuboCop itself.
  # See `CopsDocumentationGenerator::STRUCTURE` for available sections.
  #
  def initialize(departments: [], extra_info: {}, base_dir: Dir.pwd, plugin_name: nil)
    @departments = departments.map(&:to_sym).sort!
    @extra_info = extra_info
    @cops = RuboCop::Cop::Registry.global
    @config = RuboCop::ConfigLoader.default_configuration
    # NOTE: For example, this prevents excessive plugin loading before another task executes,
    # in cases where plugins are already loaded by `internal_investigation`.
    if plugin_name && @config.loaded_plugins.none? { |plugin| plugin.about.name == plugin_name }
      RuboCop::Plugin.integrate_plugins(RuboCop::Config.new, [plugin_name])
    end
    @base_dir = base_dir
    @docs_path = "#{base_dir}/docs/modules/ROOT"
    FileUtils.mkdir_p("#{@docs_path}/pages")
  end

  def call
    YARD::Registry.load!
    departments.each { |department| print_cops_of_department(department) }

    print_table_of_contents
  ensure
    RuboCop::ConfigLoader.default_configuration = nil
  end

  private

  attr_reader :departments, :cops, :config, :docs_path

  def cops_of_department(department)
    cops.with_department(department).sort!
  end

  def cops_body(data)
    check_examples_to_have_the_default_enforced_style!(data.example_objects, data.cop)

    content = +''
    STRUCTURE.each do |section, block|
      content << instance_exec(data, &block)
      content << @extra_info[section].call(data) if @extra_info[section]
    end
    content
  end

  def check_examples_to_have_the_default_enforced_style!(example_objects, cop)
    return if example_objects.none?

    examples_describing_enforced_style = example_objects.map(&:name).grep(/EnforcedStyle:/)
    return if examples_describing_enforced_style.none?

    if examples_describing_enforced_style.index { |name| name.match?('default') }.nonzero?
      raise "Put the example with the default EnforcedStyle on top for #{cop.cop_name}"
    end

    return if examples_describing_enforced_style.any? { |name| name.match?('default') }

    raise "Specify the default EnforcedStyle for #{cop.cop_name}"
  end

  def examples(example_objects, cop)
    return '' if example_objects.none?

    example_objects.each_with_object(cop_subsection('Examples', cop).dup) do |example, content|
      content << "\n" unless content.end_with?("\n\n")
      content << example_header(example.name, cop) unless example.name == ''
      content << code_example(example)
    end
  end

  def safety_object(safety_objects, cop)
    return '' if safety_objects.all? { |s| s.text.blank? }

    safety_objects.each_with_object(cop_subsection('Safety', cop).dup) do |safety_object, content|
      next if safety_object.text.blank?

      content << "\n" unless content.end_with?("\n\n")
      content << safety_object.text
      content << "\n"
    end
  end

  def required_ruby_version(cop)
    return '' unless cop.respond_to?(:required_minimum_ruby_version)

    if cop.required_minimum_ruby_version
      requirement = cop.required_minimum_ruby_version
    elsif cop.required_maximum_ruby_version
      requirement = "<= #{cop.required_maximum_ruby_version}"
    else
      return ''
    end

    "NOTE: Requires Ruby version #{requirement}\n\n"
  end

  # rubocop:disable Metrics/MethodLength
  def properties(cop)
    header = [
      'Enabled by default', 'Safe', 'Supports autocorrection', 'Version Added',
      'Version Changed'
    ]
    autocorrect = if cop.support_autocorrect?
                    context = cop.new.always_autocorrect? ? 'Always' : 'Command-line only'

                    "#{context}#{' (Unsafe)' unless cop.new(config).safe_autocorrect?}"
                  else
                    'No'
                  end
    cop_config = config.for_cop(cop)
    content = [[
      cop_status(cop_config.fetch('Enabled')),
      cop_config.fetch('Safe', true) ? 'Yes' : 'No',
      autocorrect,
      cop_config.fetch('VersionAdded', '-'),
      cop_config.fetch('VersionChanged', '-')
    ]]
    "#{to_table(header, content)}\n"
  end
  # rubocop:enable Metrics/MethodLength

  def cop_header(cop)
    content = +"\n"
    content << "[##{to_anchor(cop.cop_name)}]\n"
    content << "== #{cop.cop_name}\n"
    content << "\n"
    content
  end

  def cop_subsection(title, cop)
    content = +"\n"
    content << "[##{to_anchor(title)}-#{to_anchor(cop.cop_name)}]\n"
    content << "=== #{title}\n"
    content << "\n"
    content
  end

  def example_header(title, cop)
    content = +"[##{to_anchor(title)}-#{to_anchor(cop.cop_name)}]\n"
    content << "==== #{title}\n"
    content << "\n"
    content
  end

  def code_example(ruby_code)
    content = +"[source,ruby]\n----\n"
    content << ruby_code.text.gsub('@good', '# good').gsub('@bad', '# bad').strip
    content << "\n----\n"
    content
  end

  def configurations(department, cop, cop_config)
    header = ['Name', 'Default value', 'Configurable values']
    configs = cop_config
              .each_key
              .reject { |key| key.start_with?('Supported') }
              .reject { |key| key.start_with?('AllowMultipleStyles') }
    return '' if configs.empty?

    content = configs.map do |name|
      configurable = configurable_values(cop_config, name)
      default = format_table_value(cop_config[name])

      [configuration_name(department, name), default, configurable]
    end

    cop_subsection('Configurable attributes', cop) + to_table(header, content)
  end

  def configuration_name(department, name)
    return name unless name == 'AllowMultilineFinalElement'

    filename = "#{department_to_basename(department)}.adoc"
    "xref:#{filename}#allowmultilinefinalelement[AllowMultilineFinalElement]"
  end

  # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
  def configurable_values(cop_config, name)
    case name
    when /^Enforced/
      supported_style_name = RuboCop::Cop::Util.to_supported_styles(name)
      format_table_value(cop_config[supported_style_name])
    when 'IndentationWidth'
      'Integer'
    when 'Database'
      format_table_value(cop_config['SupportedDatabases'])
    else
      case cop_config[name]
      when String
        'String'
      when Integer
        'Integer'
      when Float
        'Float'
      when true, false
        'Boolean'
      when Array
        'Array'
      else
        ''
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity,Metrics/MethodLength

  def to_table(header, content)
    table = ['|===', "| #{header.join(' | ')}\n\n"].join("\n")
    marked_contents = content.map do |plain_content|
      # Escape `|` with backslash to prevent the regexp `|` is not used as a table separator.
      plain_content.map { |c| "| #{c.gsub('|', '\|')}" }.join("\n")
    end
    table << marked_contents.join("\n\n")
    table << "\n|===\n"
  end

  def format_table_value(val)
    value =
      case val
      when Array
        if val.empty?
          '`[]`'
        else
          val.map { |config| format_table_value(config) }.join(', ')
        end
      else
        wrap_backtick(val.nil? ? '<none>' : val)
      end
    value.gsub("#{@base_dir}/", '').rstrip
  end

  def wrap_backtick(value)
    if value.is_a?(String)
      # Use `+` to prevent text like `**/*.gemspec`, `spec/**/*` from being bold.
      value.include?('*') ? "`+#{value}+`" : "`#{value}`"
    else
      "`#{value}`"
    end
  end

  def references(cop, see_objects) # rubocop:disable Metrics/AbcSize
    cop_config = config.for_cop(cop)
    urls = RuboCop::Cop::MessageAnnotator.new(config, cop.name, cop_config, {}).urls
    return '' if urls.empty? && see_objects.empty?

    content = cop_subsection('References', cop)
    content << urls.map { |url| "* #{url}" }.join("\n")
    content << "\n" unless urls.empty?
    content << see_objects.map { |see| "* #{see.name}" }.join("\n")
    content << "\n" unless see_objects.empty?
    content
  end

  def footer_for_department(department)
    return '' unless department == :Layout

    filename = "#{department_to_basename(department)}_footer.adoc"
    file = "#{docs_path}/partials/#{filename}"
    return '' unless File.exist?(file)

    "\ninclude::../partials/#{filename}[]\n"
  end

  # rubocop:disable Metrics/MethodLength
  def print_cops_of_department(department)
    selected_cops = cops_of_department(department)
    content = +<<~HEADER
      ////
        Do NOT edit this file by hand directly, as it is automatically generated.

        Please make any necessary changes to the cop documentation within the source files themselves.
      ////

      = #{department}
    HEADER
    selected_cops.each { |cop| content << print_cop_with_doc(cop) }
    content << footer_for_department(department)
    file_name = "#{docs_path}/pages/#{department_to_basename(department)}.adoc"
    File.open(file_name, 'w') do |file|
      puts "* generated #{file_name}"
      file.write("#{content.strip}\n")
    end
  end
  # rubocop:enable Metrics/MethodLength

  def print_cop_with_doc(cop) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    cop_config = config.for_cop(cop)
    non_display_keys = %w[
      Enabled
      Description
      StyleGuide
      Reference References
      Safe SafeAutoCorrect AutoCorrect
      VersionAdded VersionChanged
    ]
    parameters = cop_config.reject { |k| non_display_keys.include? k }
    description = 'No documentation'
    example_objects = safety_objects = see_objects = []
    cop_code(cop) do |code_object|
      description = code_object.docstring unless code_object.docstring.blank?
      example_objects = code_object.tags('example')
      safety_objects = code_object.tags('safety')
      see_objects = code_object.tags('see')
    end
    data = CopData.new(cop: cop, description: description, example_objects: example_objects,
                       safety_objects: safety_objects, see_objects: see_objects, config: parameters)
    cops_body(data)
  end

  def cop_code(cop)
    YARD::Registry.all(:class).detect do |code_object|
      next unless RuboCop::Cop::Badge.for(code_object.to_s) == cop.badge

      yield code_object
    end
  end

  def table_of_content_for_department(department)
    type_title = department[0].upcase + department[1..]
    filename = "#{department_to_basename(department)}.adoc"
    content = +"=== Department xref:#{filename}[#{type_title}]\n\n"
    cops_of_department(department).each do |cop|
      anchor = to_anchor(cop.cop_name)
      content << "* xref:#{filename}##{anchor}[#{cop.cop_name}]\n"
    end

    content
  end

  def print_table_of_contents
    path = "#{docs_path}/pages/cops.adoc"

    File.write(path, table_contents) and return unless File.exist?(path)

    original = File.read(path)
    content = +"// START_COP_LIST\n\n"

    content << table_contents

    content << "\n// END_COP_LIST"

    content = original.sub(%r{// START_COP_LIST.+// END_COP_LIST}m, content)
    File.write(path, content)
  end

  def table_contents
    departments.map { |department| table_of_content_for_department(department) }.join("\n")
  end

  def cop_status(status)
    return 'Disabled' unless status

    status == 'pending' ? 'Pending' : 'Enabled'
  end

  # HTML anchor are somewhat limited in what characters they can contain, just
  # accept a known-good subset. As long as it's consistent it doesn't matter.
  #
  # Style/AccessModifierDeclarations => styleaccessmodifierdeclarations
  # OnlyFor: [] (default) => onlyfor_-__-_default_
  def to_anchor(title)
    title.delete('/').tr(' ', '-').gsub(/[^a-zA-Z0-9-]/, '_').downcase
  end
end
