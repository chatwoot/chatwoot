if %w[application sidekiq whenever].include? node[:opsworks][:instance][:layers].first
  rails_env = new_resource.environment['RAILS_ENV']
  shared_path = "#{new_resource.deploy_to}/shared"

  # key is rails app path, value is shared directory path
  directories = {
    'public/assets' => 'assets',
    'tmp/cache' => 'tmp/cache'
  }

  # creating directories and symlinking
  directories.each do |_release_path, _shared_path|
    directory "#{shared_path}/#{_shared_path}" do
      mode 0o770
      action :create
      recursive true
      not_if do
        Dir.exist?("#{shared_path}/#{_shared_path}")
      end
    end

    link "#{release_path}/#{_release_path}" do
      to "#{shared_path}/#{_shared_path}"
    end
  end

  if node[:opsworks][:instance][:layers].first.eql?('application')
    # precompile assets into public/assets (which is symlinked to shared assets folder)
    # execute "rake assets:precompile" do
    #   cwd release_path
    #   command "bundle exec rake assets:precompile --trace"
    #   environment 'RAILS_ENV' => rails_env
    # end

    # migrations
    master_node = node[:opsworks][:layers]['application'][:instances].keys.min if node[:opsworks][:layers] && node[:opsworks][:layers]['application'] && node[:opsworks][:layers]['application'][:instances]
    if master_node && node[:opsworks][:instance][:hostname].include?(master_node)
      execute 'rake db:migrate' do
        cwd release_path
        command 'bundle exec rake db:migrate --trace'
        environment 'RAILS_ENV' => rails_env
      end
    end
  end

end
