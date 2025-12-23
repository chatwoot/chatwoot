# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.add_include_dirs("lib",
                     "../../ruby_parser/dev/lib",
                     "../../sexp_processor/dev/lib")

Hoe.plugin :seattlerb
Hoe.plugin :isolate
Hoe.plugin :rdoc

Hoe.spec 'ruby2ruby' do
  developer 'Ryan Davis', 'ryand-ruby@zenspider.com'

  license "MIT"

  dependency "sexp_processor", "~> 4.6"
  dependency "ruby_parser",    "~> 3.1"
end

def process ruby, file="stdin"
  require "ruby_parser"
  require "ruby2ruby"

  parser    = RubyParser.new
  ruby2ruby = Ruby2Ruby.new

  begin
    sexp = parser.process(ruby, file)

    pp sexp if ENV["SEXP"]

    ruby2ruby.process(sexp)
  rescue Interrupt => e
    raise e
  end
end

task :stress do
  $: << "lib"
  $: << "../../ruby_parser/dev/lib"
  require "pp"

  files = Dir["../../*/dev/**/*.rb"].reject { |s| s =~ %r%/gems/% }

  warn "Stress testing against #{files.size} files"

  bad = {}

  files.each do |file|
    warn file

    begin
      process File.read(file), file
    rescue Interrupt => e
      raise e
    rescue Exception => e
      bad[file] = e
    end
  end

  pp bad
end

task :debug => :isolate do
  ENV["V"] ||= "18"

  file = ENV["F"] || ENV["FILE"]

  ruby = if file then
           File.read(file)
         else
           file = "env"
           ENV["R"] || ENV["RUBY"]
         end

  puts process(ruby, file)
end

task :parse => :isolate do
  require "ruby_parser"
  require "pp"

  parser = RubyParser.for_current_ruby

  file = ENV["F"]
  ruby = ENV["R"]

  if ruby then
    file = "env"
  else
    ruby = File.read file
  end

  pp parser.process(ruby, file)
end

task :bugs do
  sh "for f in bug*.rb ; do #{Gem.ruby} -S rake debug F=$f && rm $f ; done"
end

# vim: syntax=ruby
