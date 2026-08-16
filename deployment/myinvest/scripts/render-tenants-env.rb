#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

credentials_path, env_path = ARGV
abort 'Usage: render-tenants-env.rb <credentials-json> <env-file>' unless credentials_path && env_path

tenants = JSON.parse(File.read(credentials_path))
expected_keys = %w[saas new_academy legacy_academy]
actual_keys = tenants.map { |tenant| tenant.fetch('key') }
abort 'Tenant credentials do not contain the exact three canonical keys' unless actual_keys.sort == expected_keys.sort

tenants.each do |tenant|
  abort 'Invalid tenant account ID' unless tenant.fetch('accountId').is_a?(Integer) && tenant.fetch('accountId').positive?
  %w[webhookSecret agentBotToken].each do |key|
    abort "Invalid tenant credential: #{key}" unless tenant.fetch(key).is_a?(String) && tenant.fetch(key).length >= 24
  end
end

json = JSON.generate(tenants)
lines = File.readlines(env_path, chomp: true)
replacement = "TENANTS_JSON='#{json}'"
index = lines.index { |line| line.start_with?('TENANTS_JSON=') }
index ? lines[index] = replacement : lines << replacement

temporary_path = "#{env_path}.tmp.#{Process.pid}"
File.open(temporary_path, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
  file.write(lines.join("\n"))
  file.write("\n")
end
File.rename(temporary_path, env_path)
File.chmod(0o600, env_path)
puts 'Tenant configuration written without exposing credentials.'
