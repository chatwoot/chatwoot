# -*- ruby -*-

require "rubygems"
require "hoe"

Hoe.plugin :seattlerb
Hoe.plugin :racc
Hoe.plugin :isolate
Hoe.plugin :rdoc

Hoe.add_include_dirs "lib"
Hoe.add_include_dirs "../../sexp_processor/dev/lib"
Hoe.add_include_dirs "../../minitest/dev/lib"
Hoe.add_include_dirs "../../oedipus_lex/dev/lib"
Hoe.add_include_dirs "../../ruby2ruby/dev/lib"

V2   = %w[20 21 22 23 24 25 26 27]
V3   = %w[30 31 32]

VERS = V2 + V3

ENV["FAST"] = VERS.last if ENV["FAST"] && !VERS.include?(ENV["FAST"])
VERS.replace [ENV["FAST"]] if ENV["FAST"]

Hoe.spec "ruby_parser" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  license "MIT"

  dependency "sexp_processor", "~> 4.16"
  dependency "rake", [">= 10", "< 15"], :developer
  dependency "oedipus_lex", "~> 2.6", :developer

  # NOTE: Ryan!!! Stop trying to fix this dependency! Isolate just
  # can't handle having a faux-gem half-installed! Stop! Just `gem
  # install racc` and move on. Revisit this ONLY once racc-compiler
  # gets split out.

  dependency "racc", "~> 1.5", :developer

  require_ruby_version [">= 2.6", "< 4"]

  if plugin? :perforce then     # generated files
    VERS.each do |n|
      self.perforce_ignore << "lib/ruby#{n}_parser.rb"
    end

    VERS.each do |n|
      self.perforce_ignore << "lib/ruby#{n}_parser.y"
    end

    self.perforce_ignore << "lib/ruby_lexer.rex.rb"
  end

  if plugin?(:racc)
    self.racc_flags << " -t" if ENV["DEBUG"]
    self.racc_flags << " --superclass RubyParser::Parser"
    # self.racc_flags << " --runtime ruby_parser" # TODO: broken in racc
  end
end

def maybe_add_to_top path, string
  file = File.read path

  return if file.start_with? string

  warn "Altering top of #{path}"
  tmp_path = "#{path}.tmp"
  File.open(tmp_path, "w") do |f|
    f.puts string
    f.puts

    f.write file
    # TODO: make this deal with encoding comments properly?
  end
  File.rename tmp_path, path
end

def unifdef?
  @unifdef ||= system("which unifdef") or abort <<~EOM
    unifdef not found!

    Please install 'unifdef' package on your system or `rake generate` on a mac.
  EOM
end

V2.each do |n|
  file "lib/ruby#{n}_parser.y" => "lib/ruby_parser.yy" do |t|
    unifdef?
    cmd = 'unifdef -tk -DV=%s -UDEAD %s > %s || true' % [n, t.source, t.name]
    sh cmd
  end

  file "lib/ruby#{n}_parser.rb" => "lib/ruby#{n}_parser.y"
end

V3.each do |n|
  file "lib/ruby#{n}_parser.y" => "lib/ruby3_parser.yy" do |t|
    unifdef?
    cmd = 'unifdef -tk -DV=%s -UDEAD %s > %s || true' % [n, t.source, t.name]
    sh cmd
  end

  file "lib/ruby#{n}_parser.rb" => "lib/ruby#{n}_parser.y"
end

file "lib/ruby_lexer.rex.rb" => "lib/ruby_lexer.rex"

task :parser do |t|
  t.prerequisite_tasks.grep(Rake::FileTask).select(&:already_invoked).each do |f|
    maybe_add_to_top f.name, "# frozen_string_literal: true"
  end
end

task :generate => [:lexer, :parser]

task :clean do
  rm_rf(Dir["**/*~"] +
        Dir["diff.diff"] + # not all diffs. bit me too many times
        Dir["coverage.info"] +
        Dir["coverage"] +
        Dir["lib/ruby2*_parser.y"] +
        Dir["lib/ruby3*_parser.y"] +
        Dir["lib/*.output"])
end

task :sort do
  sh "grepsort '^ +def' lib/ruby_lexer.rb"
  sh "grepsort '^ +def (test|util)' test/test_ruby_lexer.rb"
end

desc "what was that command again?"
task :huh? do
  puts "ruby #{Hoe::RUBY_FLAGS} bin/ruby_parse -q -g ..."
end

def (task(:phony)).timestamp
  Time.at 0
end

task :isolate => :phony

def in_compare
  Dir.chdir "compare" do
    yield
  end
end

def dl v
  dir = v[/^\d+\.\d+/]
  url = "https://cache.ruby-lang.org/pub/ruby/#{dir}/ruby-#{v}.tar.xz"
  path = File.basename url
  unless File.exist? path then
    system "curl -O #{url}"
  end
end

def ruby_parse version
  v         = version[/^\d+\.\d+/].delete "."
  rp_txt    = "rp#{v}.txt"
  mri_txt   = "mri#{v}.txt"
  parse_y   = "parse#{v}.y"
  tarball   = "ruby-#{version}.tar.xz"
  ruby_dir  = "ruby-#{version}"
  diff      = "diff#{v}.diff"
  rp_out    = "lib/ruby#{v}_parser.output"
  _rp_y     = "lib/ruby#{v}_parser.y"
  rp_y_rb   = "lib/ruby#{v}_parser.rb"

  c_diff    = "compare/#{diff}"
  c_rp_txt  = "compare/#{rp_txt}"
  c_mri_txt = "compare/#{mri_txt}"
  c_parse_y = "compare/#{parse_y}"
  c_tarball = "compare/#{tarball}"
  normalize = "compare/normalize.rb"

  file c_tarball do
    in_compare do
      dl version
    end
  end

  desc "fetch all tarballs"
  task :fetch => c_tarball

  file c_parse_y => c_tarball do
    in_compare do
      extract_glob = case
                     # defs/id.def
                     when version > "3.2" then
                       "{id.h,parse.y,tool/{id2token.rb,lib/vpath.rb},defs/id.def}"
                     when version > "2.7" then
                       "{id.h,parse.y,tool/{id2token.rb,lib/vpath.rb}}"
                     else
                       "{id.h,parse.y,tool/{id2token.rb,vpath.rb}}"
                     end
      system "tar Jxf #{tarball} #{ruby_dir}/#{extract_glob}"

      Dir.chdir ruby_dir do
        if File.exist? "tool/id2token.rb" then
          args = version < "3.2" ? "--path-separator=.:./ id.h" : ""
          sh "ruby tool/id2token.rb #{args} parse.y | expand > ../#{parse_y}"
        else
          sh "expand parse.y > ../#{parse_y}"
        end

        ruby "-pi", "-e", 'gsub(/^%pure-parser/, "%define api.pure")', "../#{parse_y}"
      end
      sh "rm -rf #{ruby_dir}"
    end
  end

  bison = Dir["/opt/homebrew/opt/bison/bin/bison",
              "/usr/local/opt/bison/bin/bison",
              `which bison`.chomp,
             ].first

  file c_mri_txt => [c_parse_y, normalize] do
    in_compare do
      sh "#{bison} -r all #{parse_y}"
      sh "./normalize.rb parse#{v}.output > #{mri_txt}"
      rm ["parse#{v}.output", "parse#{v}.tab.c"]
    end
  end

  file rp_out => rp_y_rb

  file c_rp_txt => [rp_out, normalize] do
    in_compare do
      sh "./normalize.rb ../#{rp_out} > #{rp_txt}"
    end
  end

  compare = "compare#{v}"

  desc "Compare all grammars to MRI"
  task :compare => compare

  file c_diff => [c_mri_txt, c_rp_txt] do
    in_compare do
      sh "diff -du #{mri_txt} #{rp_txt} > #{diff}; true"
    end
  end

  desc "Compare #{v} grammar to MRI #{version}"
  task compare => c_diff do
    in_compare do
      system "wc -l #{diff}"
    end
  end

  task :clean do
    rm_f Dir[c_mri_txt, c_rp_txt]
  end

  task :realclean do
    rm_f Dir[c_parse_y, c_tarball]
  end
end

task :versions do
  require "open-uri"
  require "net/http" # avoid require issues in threads
  require "net/https"

  versions = VERS.map { |s| s.split(//).join "." }

  base_url = "https://cache.ruby-lang.org/pub/ruby"

  class Array
    def human_sort
      sort_by { |item| item.to_s.split(/(\d+)/).map { |e| [e.to_i, e] } }
    end
  end

  versions = versions.map { |ver|
    Thread.new {
      URI
        .parse("#{base_url}/#{ver}/")
        .read
        .scan(/ruby-\d+\.\d+\.\d+[-\w.]*?.tar.gz/)
        .reject { |s| s =~ /-(?:rc|preview)\d/ }
        .human_sort
        .last
        .delete_prefix("ruby-")
        .delete_suffix ".tar.gz"
    }
  }.map(&:value).sort

  puts versions.map { |v| "ruby_parse %p" % [v] }
end

ruby_parse "2.0.0-p648"
ruby_parse "2.1.10"
ruby_parse "2.2.10"
ruby_parse "2.3.8"
ruby_parse "2.4.10"
ruby_parse "2.5.9"
ruby_parse "2.6.10"
ruby_parse "2.7.7"
ruby_parse "3.0.5"
ruby_parse "3.1.3"
ruby_parse "3.2.1"

task :debug => :isolate do
  ENV["V"] ||= VERS.last
  Rake.application[:parser].invoke # this way we can have DEBUG set
  Rake.application[:lexer].invoke # this way we can have DEBUG set

  $:.unshift "lib"
  require "ruby_parser"
  require "pp"

  klass = Object.const_get("Ruby#{ENV["V"]}Parser") rescue nil
  raise "Unsupported version #{ENV["V"]}" unless klass
  parser = klass.new

  time = (ENV["RP_TIMEOUT"] || 10).to_i

  n = ENV["BUG"]
  file = (n && "bug#{n}.rb") || ENV["F"] || ENV["FILE"] || "debug.rb"
  ruby = ENV["R"] || ENV["RUBY"]

  if ruby then
    file = "env"
  else
    ruby = File.read file
  end


  begin
    pp parser.process(ruby, file, time)
  rescue ArgumentError, Racc::ParseError => e
    p e
    puts e.backtrace.join "\n  "
    ss = parser.lexer.ss
    src = ss.string
    lines = src[0..ss.pos].split(/\n/)
    abort "on #{file}:#{lines.size}"
  end
end

task :debug3 do
  file    = ENV["F"] || "debug.rb"
  version = ENV["V"] || ""
  verbose = ENV["VERBOSE"] ? "-v" : ""
  munge    = "./tools/munge.rb #{verbose}"

  abort "Need a file to parse, via: F=path.rb" unless file

  ENV.delete "V"

  ruby = "ruby#{version}"

  sh "#{ruby} -v"
  sh "#{ruby} -y #{file} 2>&1 | #{munge} > tmp/ruby"
  sh "#{ruby} ./tools/ripper.rb -d #{file} | #{munge} > tmp/rip"
  sh "rake debug F=#{file} DEBUG=1 2>&1 | #{munge} > tmp/rp"
  sh "diff -U 999 -d tmp/{ruby,rp}"
end

task :cmp do
  sh %(emacsclient --eval '(ediff-files "tmp/ruby" "tmp/rp")')
end

task :cmp3 do
  sh %(emacsclient --eval '(ediff-files3 "tmp/ruby" "tmp/rip" "tmp/rp")')
end

task :extract => :isolate do
  ENV["V"] ||= VERS.last
  Rake.application[:parser].invoke # this way we can have DEBUG set

  file = ENV["F"] || ENV["FILE"] || abort("Need to provide F=<path>")

  ruby "-Ilib", "bin/ruby_parse_extract_error", file
end

task :parse => :isolate do
  ENV["V"] ||= VERS.last
  Rake.application[:parser].invoke # this way we can have DEBUG set

  file = ENV["F"] || ENV["FILE"] || abort("Need to provide F=<path>")

  ruby "-Ilib", "bin/ruby_parse", file
end

task :bugs do
  sh "for f in bug*.rb bad*.rb ; do #{Gem.ruby} -S rake debug F=$f && rm $f ; done"
end

# vim: syntax=Ruby
