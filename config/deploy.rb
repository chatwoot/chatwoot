# frozen_string_literal: true

require 'mina/rails'
require 'mina/git'
# require 'mina/rbenv'  # for rbenv support. (https://rbenv.org)
# require 'mina/rvm'    # for rvm support. (https://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :puma_state, "#{fetch(:deploy_to)}/shared/tmp/sockets/puma.state"
set :puma_socket, "#{fetch(:deploy_to)}/shared/tmp/sockets/puma.sock"
set :puma_pid, "#{fetch(:deploy_to)}/shared/tmp/pids/puma.pid"
set :start_port, 3002

set :application_name, 'oncot_chatwoot'
set :domain, '13.232.218.250'
set :deploy_to, '/home/ubuntu/oncot/chatwoot'
set :repository, 'git@github.com:joshsoftware/chatwoot.git'
set :branch, 'feature/chatwoot'
set :rvm_use_path, '/home/ubuntu/.rvm/bin/rvm'

# Optional settings:
set :user, 'ubuntu' # Username in the server to SSH to.
#   set :port, '30000'           # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

set :shared_dirs, fetch(:shared_dirs, []).push('log', 'tmp/pids', 'tmp/sockets', 'public/uploads')

set :shared_files, fetch(:shared_files, []).push('config/puma.rb')

# Shared dirs and files will be symlinked into the app-folder by the 'deploy:link_shared_paths' step.
# Some plugins already add folders to shared_dirs like `mina/rails` add `public/assets`, `vendor/bundle` and many more
# run `mina -d` to see all folders and files already included in `shared_dirs` and `shared_files`
# set :shared_dirs, fetch(:shared_dirs, []).push('public/assets')
# set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/secrets.yml')

# This task is the environment that is loaded for all remote run commands, such as
# `mina deploy` or `mina rake`.
task :remote_environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  command %( source ~/.rvm/scripts/rvm )
  command %( rvm use 3.0.2 )
end

# Put any custom commands you need to run at setup
# All paths in `shared_dirs` and `shared_paths` will be created on their own.
task :setup do
  # command %{rbenv install 2.3.0 --skip-existing}
  # command %(touch "#{fetch(:shared_path)}/config/application.yml")
  command %(touch "#{fetch(:shared_path)}/config/puma.rb")
  command %(touch "#{fetch(:shared_path)}/tmp/sockets/puma.state")
  command %(touch "#{fetch(:shared_path)}/tmp/sockets/puma.sock")
  command %(touch "#{fetch(:shared_path)}/tmp/pids/puma.pid")
end

desc 'Deploys the current version to the server.'
task deploy: :remote_environment do
  # uncomment this line to make sure you pushed your local branch to the remote origin
  # invoke :'git:ensure_pushed'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    # invoke :'rails:db_schema_load'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
      in_path(fetch(:current_path)) do
        command %(mkdir -p tmp/)
        # command %(touch tmp/restart.txt)
        # command %{RAILS_ENV=production bundle exec anycable}
        # command %(sudo service sidekiq restart)
        command %(foreman start -f Procfile.dev)
        command %(pumactl restart)
      end
    end
  end

  # you can use `run :local` to run tasks on local machine before of after the deploy scripts
  # run(:local){ say 'done' }
end

task puma_start: :remote_environment do
  command %(
    if [ -e '#{fetch(:puma_pid)}' ]; then
      echo 'Puma is already running'
    else
      echo 'Start Puma'
      cd #{fetch(:current_path)} && bundle exec puma -q -d -e #{fetch(:rails_env)} -C #{fetch(:current_path)}/config/puma.rb -p #{fetch(:start_port)} -S #{fetch(:puma_state)} -b "unix://#{fetch(:deploy_to)}#{fetch(:puma_socket)}" --pidfile #{fetch(:puma_pid)}
    fi
  )
end

task puma_restart: :remote_environment do
  command %(
    if [ -e '#{fetch(:puma_pid)}' ]; then
      echo 'Restart Puma'
      cd #{fetch(:current_path)} && bundle exec pumactl -S #{fetch(:puma_state)} restart
    else
      echo 'Start Puma'
      cd #{fetch(:current_path)} && bundle exec puma -q -d -e #{fetch(:rails_env)} -C #{fetch(:current_path)}/config/puma.rb -p #{fetch(:start_port)} -S #{fetch(:puma_state)} -b "unix://#{fetch(:puma_socket)}" --pidfile #{fetch(:puma_pid)}
    fi
  )
end

task puma_stop: :remote_environment do
  command %(
    if [ -e '#{fetch(:puma_pid)}' ]; then
      cd #{fetch(:current_path)} && bundle exec pumactl -S #{fetch(:puma_state)} stop
      rm #{fetch(:puma_socket)}
      rm #{fetch(:puma_state)}
      rm #{fetch(:puma_pid)}
    else
      echo 'Puma is not running. Phew!!!'
    fi
  )
end

# For help in making your deploy script, see the Mina documentation:
#
#  - https://github.com/mina-deploy/mina/tree/master/docs

# oncot.joshsoftware.com
# oncot-api.joshsoftware.com
# oncot-compiler.joshsoftware.com

# DNS mapping done