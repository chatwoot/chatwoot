#!/usr/bin/env ruby
# frozen_string_literal: true

require 'time'
require 'json'

input = STDIN.read.split("\n")

git_sha, git_msg = `git log -n 1 --pretty="format:%H|||%s"`.split('|||')
git_date = `git log -n 1 --pretty="format:%ai"`
platform = Gem::Platform.local

def doc(payload)
  puts({ index: { _index: "benchmark-ruby" } }.to_json)
  puts(payload.to_json)
end

meta = {
  executed_at: Time.new.iso8601,
  'git.commit' => git_sha,
  'git.date' => (String(git_date).strip != '' && Time.parse(git_date).iso8601) || Time.now.iso8601,
  'git.subject' => git_msg,
  hostname: `hostname`.chomp,
  engine: RUBY_ENGINE,
  arch: platform.cpu,
  os: platform.os,
  ruby_version: "#{RUBY_ENGINE == 'jruby' ? 'j' : ''}#{RUBY_VERSION}"
}

results =
  input
  .grep(/^with/)
  .map do |line|
    title = line.match(/^(.*):/) { |m| m[1] }
    user, system, total, real = line.scan(/[0-9\.]+/).map(&:to_f)
    meta.merge(
      title: title,
      user: user,
      system: system,
      total: total,
      real: real,
    )
  end

results.each { |result| doc result }

overhead =
  (results[0][:total] - results[1][:total]) *
  1000 /  # milliseconds
  10_000     # transactions

doc meta.merge(
  title: 'overhead',
  overhead: overhead
)
