require_relative "test_helper"

class String
  def blank?
    self.strip.length == 0
  end
end

class NilClass
  def blank?
    true
  end
end

class Object
  def blank?
    false
  end
end

class DocTest < Minitest::Test
  include TestHelper

  class TestApp
    include GLI::App
  end

  class TestListener
    @@last = nil
    def self.last
      @@last
    end
    def initialize(*ignored)
      @stringio = StringIO.new
      @indent = ''
      @@last = self
    end
    def options
    end
    def end_options
    end
    def commands
    end
    def end_commands
    end
    def beginning
      @stringio << 'BEGIN' << "\n"
    end

    def ending
      @stringio << 'END' << "\n"
    end

    def program_desc(desc)
      @stringio << desc << "\n"
    end

    def program_long_desc(desc)
      @stringio << desc << "\n"
    end

    def version(version)
      @stringio << version << "\n"
    end

    def default_command(name)
      @stringio << @indent << "default_command: " << name << "\n"
    end

    def flag(name,aliases,desc,long_desc,default_value,arg_name,must_match,type)
      @stringio << @indent << "flag: " << name << "\n"
      @indent += '  '
      @stringio << @indent << "aliases: " << aliases.join(',') << "\n"   unless aliases.empty?
      @stringio << @indent << "desc: " << desc << "\n"                   unless desc.blank?
      @stringio << @indent << "long_desc: " << long_desc << "\n"         unless long_desc.blank?
      @stringio << @indent << "default_value: " << default_value << "\n" unless default_value.blank?
      @stringio << @indent << "arg_name: " << arg_name << "\n"           unless arg_name.blank?
      @indent.gsub!(/  $/,'')
    end

    def switch(name,aliases,desc,long_desc,negatable)
      @stringio << @indent << "switch: " << name << "\n"
      @indent += '  '
      @stringio << @indent << "aliases: " << aliases.join(',') << "\n"   unless aliases.empty?
      @stringio << @indent << "desc: " << desc << "\n"                   unless desc.blank?
      @stringio << @indent << "long_desc: " << long_desc << "\n"         unless long_desc.blank?
      @stringio << @indent << "negatable: " << negatable << "\n"         unless negatable.blank?
      @indent.gsub!(/  $/,'')
    end

    def command(name,aliases,desc,long_desc,arg_name)
      @stringio << @indent << "command: " << name << "\n"
      @indent += '  '
      @stringio << @indent << "aliases: " << aliases.join(',') << "\n"   unless aliases.empty?
      @stringio << @indent << "desc: " << desc << "\n"                   unless desc.blank?
      @stringio << @indent << "long_desc: " << long_desc << "\n"         unless long_desc.blank?
      @stringio << @indent << "arg_name: " << arg_name << "\n"           unless arg_name.blank?
    end

    def end_command(name)
      @indent.gsub!(/  $/,'')
      @stringio << @indent << "end #{name}" << "\n"
    end

    def to_s
      @stringio.string
    end
  end

  def setup
    @@counter = -1 # we pre-increment so this makes 0 first
  end

  def test_app_without_docs_gets_callbacks_for_each_element
    setup_test_app
    construct_expected_output
    @documenter = GLI::Commands::Doc.new(@app)
    @listener = TestListener.new
    @documenter.document(@listener)
    lines_expected = @string.split(/\n/)
    lines_got = @listener.to_s.split(/\n/)
    lines_expected.zip(lines_got).each_with_index do |(expected,got),index|
      assert_equal expected,got,"At index #{index}"
    end
  end

  def test_doc_command_works_as_GLI_command
    setup_test_app
    construct_expected_output
    @documenter = GLI::Commands::Doc.new(@app)
    @listener = TestListener.new
    @documenter.execute({},{:format => "DocTest::TestListener"},[])
    lines_expected = @string.split(/\n/)
    lines_got = TestListener.last.to_s.split(/\n/)
    lines_expected.zip(lines_got).each_with_index do |(expected,got),index|
      assert_equal expected,got,"At index #{index}"
    end
  end

private

  @@counter = 1
  def self.counter
    @@counter += 1
    @@counter
  end

  def setup_test_app
    @app = TestApp.new
    @app.instance_eval do
      program_desc "program desc"
      program_long_desc "program long desc"
      version "1.3.4"

      DocTest.flag_with_everything_specified(self)
      DocTest.flag_with_everything_omitted(self)
      DocTest.switch_with_everything_specified(self)
      DocTest.switch_with_everything_omitted(self)

      desc      "command desc"
      long_desc "command long desc"
      arg_name  "cmd_arg_name"
      command [:command1,:com1] do |c|
        DocTest.flag_with_everything_specified(c)
        DocTest.flag_with_everything_omitted(c)
        DocTest.switch_with_everything_specified(c)
        DocTest.switch_with_everything_omitted(c)

        c.desc      "subcommand desc"
        c.long_desc "subcommand long desc"
        c.arg_name  "subcmd_arg_name"
        c.action { |g,o,a| }
        c.command [:sub,:subcommand] do |sub|
          DocTest.flag_with_everything_specified(sub,:subflag)
          DocTest.flag_with_everything_omitted(sub,:subflag2)
          DocTest.switch_with_everything_specified(sub,:subswitch)
          DocTest.switch_with_everything_omitted(sub,:subswitch2)
          sub.action { |g,o,a| }
        end
        c.command [:default] do |sub|
          sub.action { |g,o,a| }
        end
        c.default_command :default
      end

      command [:command2,:com2] do |c|
        c.action { |g,o,a| }
        c.command [:sub2,:subcommand2] do |sub|
          sub.action { |g,o,a| }
        end
      end
    end
  end

  def self.flag_with_everything_specified(on,name=[:f,:flag])
    on.flag name,:desc          => "flag desc #{counter}",
                 :long_desc     => "flag long_desc #{counter}",
                 :default_value => "flag default_value #{counter}",
                 :arg_name      => "flag_arg_name_#{counter}",
                 :must_match    => /foo.*bar/,
                 :type          => Array
  end

  def self.flag_with_everything_omitted(on,name=[:F,:flag2])
    on.flag name
  end

  def self.switch_with_everything_specified(on,name=[:s,:switch])
    on.switch name, :desc      => "switch desc #{counter}",
                    :long_desc => "switch long_desc #{counter}",
                    :negatable => false
  end

  def self.switch_with_everything_omitted(on,name=[:S,:switch2])
    on.switch name
  end
  def construct_expected_output
    # Oh yeah.  Creating a string representing the structure of the calls.
    @string =<<EOS
BEGIN
program desc
program long desc
1.3.4
flag: F
  aliases: flag2
  arg_name: arg
flag: f
  aliases: flag
  desc: flag desc 0
  long_desc: flag long_desc 1
  default_value: flag default_value 2
  arg_name: flag_arg_name_3
switch: S
  aliases: switch2
  negatable: true
switch: s
  aliases: switch
  desc: switch desc 4
  long_desc: switch long_desc 5
  negatable: false
switch: version
  desc: Display the program version
  negatable: false
command: command1
  aliases: com1
  desc: command desc
  long_desc: command long desc
  arg_name: cmd_arg_name
  flag: F
    aliases: flag2
    arg_name: arg
  flag: f
    aliases: flag
    desc: flag desc 6
    long_desc: flag long_desc 7
    default_value: flag default_value 8
    arg_name: flag_arg_name_9
  switch: S
    aliases: switch2
    negatable: true
  switch: s
    aliases: switch
    desc: switch desc 10
    long_desc: switch long_desc 11
    negatable: false
  command: default
    default_command: 
  end default
  command: sub
    aliases: subcommand
    desc: subcommand desc
    long_desc: subcommand long desc
    arg_name: subcmd_arg_name
    flag: subflag
      desc: flag desc 12
      long_desc: flag long_desc 13
      default_value: flag default_value 14
      arg_name: flag_arg_name_15
    flag: subflag2
      arg_name: arg
    switch: subswitch
      desc: switch desc 16
      long_desc: switch long_desc 17
      negatable: false
    switch: subswitch2
      negatable: true
    default_command: 
  end sub
  default_command: default
end command1
command: command2
  aliases: com2
  command: sub2
    aliases: subcommand2
    default_command: 
  end sub2
  default_command: 
end command2
command: help
  desc: Shows a list of commands or help for one command
  long_desc: Gets help for the application or its commands. Can also list the commands in a way helpful to creating a bash-style completion function
  arg_name: command
  switch: c
    desc: List commands one per line, to assist with shell completion
    negatable: true
  default_command: 
end help
default_command: 
END
EOS
  end
end
