  # app/jobs/domain_config_job.rb
  # require 'fileutils'

  class DomainConfigJob < ApplicationJob
    queue_as :default

    def perform(domain_name)
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
    
        return 301 https://$host$request_uri;
      }
    NGINX
    
    # Using Ruby's file I/O with sudo to write the config file
    file_write_command = "echo '#{nginx_config}' | sudo tee #{config_filename} > /dev/null"
    if system(file_write_command)
      Rails.logger.info "Nginx config written successfully"
    else
      Rails.logger.info "Failed to write Nginx config"
    end
    

      # Enable the site by creating a symbolic link
      if system("sudo ln -sf #{config_filename} #{symlink_path}")
        Rails.logger.info "Site enabled successfully"
      else
        Rails.logger.info "Failed to enable the site"
      end

      # Reload Nginx
      Rails.logger.info "Testing and reloading Nginx configuration..."
      unless system("sudo nginx -t && sudo systemctl reload nginx")
        Rails.logger.error "Failed to apply Nginx configuration. Check for errors."
        return
      end

      # Generate SSL certificate using Certbot
      Rails.logger.info "Generating SSL certificate for #{domain_name}..."
      certbot_command = "sudo certbot --nginx -d #{domain_name} --non-interactive --agree-tos -m support@onehash.ai --redirect"
      certbot_reload_command = "sudo systemctl reload nginx"
      certbot_auto_renewal_test_command = "sudo certbot renew"

      if system(certbot_command)
        Rails.logger.info "SSL certificate successfully generated and applied for #{domain_name}."
        Rails.logger.info "Reloading Nginx to apply SSL certificate..."
        if system(certbot_reload_command)
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
  end
