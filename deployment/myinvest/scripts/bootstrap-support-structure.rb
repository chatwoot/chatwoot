#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

deployment_dir = File.expand_path('..', __dir__)
mode = ARGV.empty? ? 'dry-run' : ARGV.shift
abort 'Usage: bootstrap-support-structure.rb [--apply]' unless %w[dry-run --apply].include?(mode) && ARGV.empty?

apply = mode == '--apply'
env_path = ENV.fetch('ENV_FILE', File.join(deployment_dir, '.env'))
command = ['docker', 'compose', '--project-directory', deployment_dir, '--env-file', env_path,
           '-f', File.join(deployment_dir, 'compose.yaml'), 'run', '--rm', '-e', 'SUPPORT_STRUCTURE_RUN=true',
           '-e', "SUPPORT_STRUCTURE_MODE=#{apply ? 'apply' : 'dry-run'}"]
command.push('-e', 'SUPPORT_STRUCTURE_CONFIRMATION') if apply
command.push('rails', 'bundle', 'exec', 'rails', 'runner', '/bootstrap/support_structure.rb')

unless system({ 'SUPPORT_STRUCTURE_CONFIRMATION' => ENV['SUPPORT_STRUCTURE_CONFIRMATION'].to_s }, *command)
  warn JSON.generate(command: 'support-structure', mode: apply ? 'apply' : 'dry-run', status: 'failed')
  raise SystemExit, 1
end
