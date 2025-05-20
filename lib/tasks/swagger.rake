namespace :swagger do
  desc 'build combined swagger.json file from all the fragmented definitions and paths inside swagger folder'
  task build: :environment do
    require 'json_refs'

    base_path = Rails.root.join('swagger')
    Dir.chdir(base_path) do
      swagger_index = YAML.safe_load(File.open('index.yml'))

      final_build = JsonRefs.call(
        swagger_index,
        resolve_local_ref: false,
        resolve_file_ref: true,
        logging: true
      )
      File.write('swagger.json', JSON.pretty_generate(final_build))
      puts 'Swagger build was successful.'
      puts "Generated #{base_path}/swagger.json"
      puts 'Go to http://localhost:3000/swagger see the changes.'
      
      # Build tag group specific swagger files
      Rake::Task['swagger:build_tag_groups'].invoke
    end
  end
  
  desc 'build separate swagger files for each tag group'
  task build_tag_groups: :environment do
    require 'json_refs'
    
    base_path = Rails.root.join('swagger')
    tag_groups_path = base_path.join('tag_groups')
    
    Dir.chdir(tag_groups_path) do
      # Build for platform
      platform_yaml = YAML.safe_load(File.open('platform.yml'))
      platform_build = JsonRefs.call(
        platform_yaml,
        resolve_local_ref: false,
        resolve_file_ref: true,
        logging: true
      )
      File.write('platform_swagger.json', JSON.pretty_generate(platform_build))
      
      # Build for application
      application_yaml = YAML.safe_load(File.open('application.yml'))
      application_build = JsonRefs.call(
        application_yaml,
        resolve_local_ref: false,
        resolve_file_ref: true,
        logging: true
      )
      File.write('application_swagger.json', JSON.pretty_generate(application_build))
      
      # Build for client
      client_yaml = YAML.safe_load(File.open('client.yml'))
      client_build = JsonRefs.call(
        client_yaml,
        resolve_local_ref: false,
        resolve_file_ref: true,
        logging: true
      )
      File.write('client_swagger.json', JSON.pretty_generate(client_build))
      
      # Build for others
      others_yaml = YAML.safe_load(File.open('others.yml'))
      others_build = JsonRefs.call(
        others_yaml,
        resolve_local_ref: false,
        resolve_file_ref: true,
        logging: true
      )
      File.write('other_swagger.json', JSON.pretty_generate(others_build))
    end
    
    puts 'Tag-specific swagger files generated successfully.'
  end
end
