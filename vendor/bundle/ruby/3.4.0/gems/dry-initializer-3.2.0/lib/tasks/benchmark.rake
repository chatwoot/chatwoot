# frozen_string_literal: true

namespace :benchmark do
  desc "Runs benchmarks for plain params"
  task :plain_params do
    system "ruby benchmarks/plain_params.rb"
  end

  desc "Runs benchmarks for plain options"
  task :plain_options do
    system "ruby benchmarks/plain_options.rb"
  end

  desc "Runs benchmarks for value coercion"
  task :with_coercion do
    system "ruby benchmarks/with_coercion.rb"
  end

  desc "Runs benchmarks with defaults"
  task :with_defaults do
    system "ruby benchmarks/with_defaults.rb"
  end

  desc "Runs benchmarks with defaults and coercion"
  task :with_defaults_and_coercion do
    system "ruby benchmarks/with_defaults_and_coercion.rb"
  end

  desc "Runs benchmarks for several defaults"
  task :compare_several_defaults do
    system "ruby benchmarks/with_several_defaults.rb"
  end
end

desc "Runs all benchmarks"
task benchmark: %i[
  benchmark:plain_params
  benchmark:plain_options
  benchmark:with_coercion
  benchmark:with_defaults
  benchmark:with_defaults_and_coercion
  benchmark:compare_several_defaults
]
