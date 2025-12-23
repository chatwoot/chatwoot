# frozen_string_literal: true

# Public: Executes Vite commands, providing conveniences for debugging.
class ViteRuby::Runner
  def initialize(vite_ruby)
    @vite_ruby = vite_ruby
  end

  # Public: Executes Vite with the specified arguments.
  def run(argv, exec: false)
    config.within_root {
      cmd = command_for(argv)
      return Kernel.exec(*cmd) if exec

      log_or_noop = ->(line) { logger.info('vite') { line } } unless config.hide_build_console_output
      ViteRuby::IO.capture(*cmd, chdir: config.root, with_output: log_or_noop)
    }
  rescue Errno::ENOENT => error
    raise ViteRuby::MissingExecutableError, error
  end

private

  extend Forwardable

  def_delegators :@vite_ruby, :config, :logger, :env

  # Internal: Returns an Array with the command to run.
  def command_for(args)
    [config.to_env(env)].tap do |cmd|
      exec_args, vite_args = args.partition { |arg| arg.start_with?('--node-options') }
      cmd.push(*vite_executable(*exec_args))
      cmd.push(*vite_args)
      cmd.push('--mode', config.mode) unless args.include?('--mode') || args.include?('-m')
    end
  end

  # Internal: Resolves to an executable for Vite.
  def vite_executable(*exec_args)
    bin_path = config.vite_bin_path
    return [bin_path] if bin_path && File.exist?(bin_path)

    x = case config.package_manager
    when 'npm' then %w[npx]
    when 'pnpm' then %w[pnpm exec]
    when 'bun' then %w[bun x]
    when 'yarn' then %w[yarn]
    else raise ArgumentError, "Unknown package manager #{ config.package_manager.inspect }"
    end

    [*x, *exec_args, 'vite']
  end
end
