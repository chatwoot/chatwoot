Chef::Log.debug '==================> inside before_migrate <=================='

shared_path = '/srv/www/chatwoot/shared'

# yml files
run "ln -nfs #{shared_path}/config/application.yml #{release_path}/config/application.yml"
run "ln -nfs #{shared_path}/config/reports_redis.yml #{release_path}/config/reports_redis.yml"
