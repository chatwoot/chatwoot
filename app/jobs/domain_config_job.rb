  # app/jobs/domain_config_job.rb
  # require 'fileutils'

  class DomainConfigJob < ApplicationJob
    queue_as :default

    def perform(domain_name,initial_domain)
      Rails.logger.info "domain_name: #{domain_name}, initial_domain: #{initial_domain.inspect}"

      if initial_domain.present? && initial_domain != "undefined"
        discard_domain(initial_domain)
      end
      formatted_domain_name = domain_name.tr('.', '_')

      # Define paths
      config_filename = "/etc/nginx/sites-available/#{formatted_domain_name}.conf"
      symlink_path = "/etc/nginx/sites-enabled/#{formatted_domain_name}.conf"
      dhparam_path = "/etc/ssl/dhparam"

      # Create Diffie-Hellman parameters if they don't exist
      unless File.exist?(dhparam_path)
        Rails.logger.info "Generating Diffie-Hellman parameters..."
        system("sudo openssl dhparam -out #{dhparam_path} 2048")
      end

      nginx_config = <<~NGINX
          upstream backend_#{formatted_domain_name} {
            zone upstreams 64K;
            server 127.0.0.1:3000;
            keepalive 32;
          }

          map $http_upgrade $connection_upgrade {
            default upgrade;
            '' close;
          }

          server {
            listen 80;
            listen [::]:80;
            server_name #{domain_name};

            access_log /var/log/nginx/#{formatted_domain_name}_access_80.log;
            error_log /var/log/nginx/#{formatted_domain_name}_error_80.log;

            location / {
              proxy_pass http://backend_#{formatted_domain_name};
              proxy_redirect off;

              proxy_pass_header Authorization;
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Ssl on; # Optional
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection $connection_upgrade;

              client_max_body_size 0;
              proxy_read_timeout 36000s;
            }
          }
      NGINX
  
    config_filename = "/etc/nginx/sites-available/#{formatted_domain_name}.conf"

    # Create the config file with sudo and tee
    file_write_command = "sudo tee #{config_filename} > /dev/null"

    # Open the file and write the config content
    Open3.popen3(file_write_command) do |stdin, stdout, stderr|
      stdin.puts nginx_config
      stdin.close

      # Capture output and error messages from the tee command
      if stderr.read.empty?
        Rails.logger.info "Nginx config written successfully"
      else
        Rails.logger.info "Failed to write Nginx config: #{stderr.read}"
      end
    end
    

      # Enable the site by creating a symbolic link
      if system("sudo ln -sf #{config_filename} #{symlink_path}")
        Rails.logger.info "Site enabled successfully"
      else
        Rails.logger.info "Failed to enable the site"
      end

      # # Reload Nginx
      # Rails.logger.info "Testing and reloading Nginx configuration..."
      # unless system("sudo nginx -t && sudo systemctl reload nginx")
      #   Rails.logger.error "Failed to apply Nginx configuration. Check for errors."
      #   return
      # end

      # Generate SSL certificate using Certbot
      Rails.logger.info "Generating SSL certificate for #{domain_name}..."
      certbot_command = "sudo certbot --nginx -d #{domain_name} --non-interactive --agree-tos -m support@onehash.ai --redirect"
      certbot_test_and_reload_command = "sudo nginx -t && sudo systemctl reload nginx"
      certbot_auto_renewal_test_command = "sudo certbot renew"

      if system(certbot_command)
        Rails.logger.info "SSL certificate successfully generated and applied for #{domain_name}."
        Rails.logger.info "Testing and reloading Nginx configuration..."
        if system(certbot_test_and_reload_command)
          Rails.logger.info "Nginx reloaded successfully."
        else
          Rails.logger.error "Failed to reload Nginx. Check the logs for details."
        end

        Rails.logger.info "Testing auto-renewal for #{domain_name}..."
        if system(certbot_auto_renewal_test_command)
          Rails.logger.info "Auto-renewal test for #{domain_name} completed successfully."
          Rails.logger.info "Nginx configuration with SSL enabled for #{domain_name} is ready."
        else
          Rails.logger.error "Auto-renewal test failed. Check Certbot logs for details."
        end
      else
        Rails.logger.error "Failed to generate SSL certificate. Check Certbot logs for details."
      end

    rescue StandardError => e
      Rails.logger.error "Error occurred: #{e.message}"
    end

    private

    def discard_domain(initial_domain)
      formatted_initial_domain = initial_domain.tr('.', '_')
      config_filename = "/etc/nginx/sites-available/#{formatted_initial_domain}.conf"
      symlink_path = "/etc/nginx/sites-enabled/#{formatted_initial_domain}.conf"
    
      # Delete Certbot certificate first
      Rails.logger.info "Deleting Certbot certificate for #{initial_domain}..."
      certbot_delete_command = "sudo certbot delete --cert-name #{formatted_initial_domain}"
      if system(certbot_delete_command)
        Rails.logger.info "Certbot certificate deleted successfully for #{initial_domain}."
      else
        Rails.logger.error "Failed to delete Certbot certificate for #{initial_domain}."
      end
    
      # Delete Nginx configuration
      if system("sudo rm #{config_filename}")
        Rails.logger.info "Nginx config removed successfully for #{initial_domain}."
      else
        Rails.logger.error "Failed to remove Nginx config for #{initial_domain}."
      end
    
      if system("sudo rm #{symlink_path}")
        Rails.logger.info "Site disabled successfully for #{initial_domain}."
      else
        Rails.logger.error "Failed to disable the site for #{initial_domain}."
      end
    
      # Reload Nginx
      Rails.logger.info "Testing and reloading Nginx configuration..."
      unless system("sudo nginx -t && sudo systemctl reload nginx")
        Rails.logger.error "Nginx configuration test or reload failed."
      else
        Rails.logger.info "Nginx reloaded successfully after changes for #{initial_domain}."
      end
    end    
  end
