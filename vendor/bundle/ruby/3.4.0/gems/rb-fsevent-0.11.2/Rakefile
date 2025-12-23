# -*- encoding: utf-8 -*-
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

namespace(:spec) do
  desc "Run all specs on multiple ruby versions"
  task(:portability) do
    versions = %w[2.4.1 rbx-3.72 jruby-1.7.26 jruby-9.1.8.0]
    versions.each do |version|
      # system <<-BASH
      #   bash -c 'source ~/.rvm/scripts/rvm;
      #            rvm #{version};
      #            echo "--------- version #{version} ----------\n";
      #            bundle install;
      #            rake spec'
      # BASH
      system <<-BASH
        bash -c 'export PATH="$HOME/.rbenv/bin:$PATH";
                 [[ `which rbenv` ]] && eval "$(rbenv init -)";
                 [[ ! -a $HOME/.rbenv/versions/#{version} ]] && rbenv install #{version};
                 rbenv shell #{version};
                 rbenv which bundle 2> /dev/null || gem install bundler;
                 rm Gemfile.lock;
                 bundle install;
                 rake spec;'
      BASH
    end
  end
end
