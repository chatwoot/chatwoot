require "foreman/export"
require "ostruct"
require "pathname"
require "shellwords"

class Foreman::Export::Base

  attr_reader :location
  attr_reader :engine
  attr_reader :options
  attr_reader :formation

  # deprecated
  attr_reader :port

  def initialize(location, engine, options={})
    @location  = location
    @engine    = engine
    @options   = options.dup
    @formation = engine.formation

    # deprecated
    def port
      Foreman::Export::Base.warn_deprecation!
      engine.base_port
    end

    # deprecated
    def template
      Foreman::Export::Base.warn_deprecation!
      options[:template]
    end

    # deprecated
    def @engine.procfile
      Foreman::Export::Base.warn_deprecation!
      @processes.map do |process|
        OpenStruct.new(
          :name => @names[process],
          :process => process
        )
      end
    end
  end

  def export
    error("Must specify a location") unless location
    FileUtils.mkdir_p(location) rescue error("Could not create: #{location}")
    chown user, log
    chown user, run
  end

  def app
    options[:app] || "app"
  end

  def log
    options[:log] || "/var/log/#{app}"
  end

  def run
    options[:run] || "/var/run/#{app}"
  end

  def user
    options[:user] || app
  end

private ######################################################################

  def self.warn_deprecation!
    @@deprecation_warned ||= false
    return if @@deprecation_warned
    puts "WARNING: Using deprecated exporter interface. Please update your exporter"
    puts "the interface shown in the upstart exporter:"
    puts
    puts "https://github.com/ddollar/foreman/blob/master/lib/foreman/export/upstart.rb"
    puts "https://github.com/ddollar/foreman/blob/master/data/export/upstart/process.conf.erb"
    puts
    @@deprecation_warned = true
  end

  def chown user, dir
    FileUtils.chown user, nil, dir
  rescue
    error("Could not chown #{dir} to #{user}") unless File.writable?(dir) || ! File.exists?(dir)
  end

  def error(message)
    raise Foreman::Export::Exception.new(message)
  end

  def say(message)
    puts "[foreman export] %s" % message
  end
  
  def clean(filename)
    return unless File.exists?(filename)
    say "cleaning up: #{filename}"
    FileUtils.rm(filename)
  end

  def clean_dir(dirname)
    return unless File.exists?(dirname)
    say "cleaning up directory: #{dirname}"
    FileUtils.rm_r(dirname)
  end

  def shell_quote(value)
    Shellwords.escape(value)
  end

  # deprecated
  def old_export_template(exporter, file, template_root)
    if template_root && File.exist?(file_path = File.join(template_root, file))
      File.read(file_path)
    elsif File.exist?(file_path = File.expand_path(File.join("~/.foreman/templates", file)))
      File.read(file_path)
    else
      File.read(File.expand_path("../../../../data/export/#{exporter}/#{file}", __FILE__))
    end
  end

  def export_template(name, file=nil, template_root=nil)
    if file && template_root
      old_export_template name, file, template_root
    else
      name_without_first = name.split("/")[1..-1].join("/")
      matchers = []
      matchers << File.join(options[:template], name_without_first) if options[:template]
      matchers << File.expand_path("~/.foreman/templates/#{name}")
      matchers << File.expand_path("../../../../data/export/#{name}", __FILE__)
      File.read(matchers.detect { |m| File.exists?(m) })
    end
  end

  def write_template(name, target, binding)
    compiled = if ERB.instance_method(:initialize).parameters.assoc(:key) # Ruby 2.6+
                 ERB.new(export_template(name), trim_mode: '-').result(binding)
               else
                 ERB.new(export_template(name), nil, '-').result(binding)
               end
    write_file target, compiled
  end

  def chmod(mode, file)
    say "setting #{file} to mode #{mode}"
    FileUtils.chmod mode, File.join(location, file)
  end

  def create_directory(dir)
    say "creating: #{dir}"
    FileUtils.mkdir_p(File.join(location, dir))
  end

  def create_symlink(link, target)
    say "symlinking: #{link} -> #{target}"
    FileUtils.symlink(target, File.join(location, link))
  end

  def write_file(filename, contents)
    say "writing: #{filename}"

    filename = File.join(location, filename) unless Pathname.new(filename).absolute?

    File.open(filename, "w") do |file|
      file.puts contents
    end
  end

end
