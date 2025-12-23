# frozen_string_literal: true

class ViteRuby::CLI::Vite < Dry::CLI::Command
  CURRENT_ENV = ENV['RACK_ENV'] || ENV['RAILS_ENV']

  def self.executable_options
    option(:mode, default: self::DEFAULT_ENV, values: %w[development production test], aliases: ['m'], desc: 'The build mode for Vite')
    option(:node_options, desc: 'Node options for the Vite executable', aliases: ['node-options'])
    option(:inspect, desc: 'Run Vite in a debugging session with node --inspect-brk', aliases: ['inspect-brk'], type: :boolean)
    option(:trace_deprecation, desc: 'Run Vite in debugging mode with node --trace-deprecation', aliases: ['trace-deprecation'], type: :boolean)
  end

  def self.shared_options
    executable_options
    option(:debug, desc: 'Run Vite in verbose mode, printing all debugging output', aliases: ['verbose'], type: :boolean)
    option(:clobber, desc: 'Clear cache and previous builds', type: :boolean, aliases: %w[clean clear])
  end

  def call(mode:, args: [], clobber: false, node_options: nil, inspect: nil, trace_deprecation: nil, **boolean_opts)
    ViteRuby.env['VITE_RUBY_MODE'] = mode
    ViteRuby.commands.clobber if clobber

    node_options = [
      node_options,
      ('--inspect-brk' if inspect),
      ('--trace-deprecation' if trace_deprecation),
    ].compact.join(' ')

    args << %(--node-options="#{ node_options }") unless node_options.empty?

    boolean_opts.map { |name, value| args << "--#{ name }" if value }

    yield(args)
  end
end
