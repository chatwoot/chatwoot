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
    
    # Load the full swagger specification
    full_spec = JSON.parse(File.read(base_path.join('swagger.json')))
    
    # Load the tag groups from index.yml
    swagger_index = YAML.safe_load(File.open(base_path.join('index.yml')))
    tag_groups = swagger_index['x-tagGroups']
    
    # Process each tag group
    tag_groups.each do |tag_group|
      group_name = tag_group['name']
      tags = tag_group['tags']
      
      # Create a copy of the full spec for this tag group
      tag_spec = full_spec.dup
      
      # Filter paths to only include those with operations tagged with any of our tags
      filtered_paths = {}
      
      full_spec['paths'].each do |path, path_item|
        # Check if any operation in this path has a tag from our group
        operations_with_our_tags = false
        
        path_item.each do |method, operation|
          next unless operation.is_a?(Hash) && operation['tags']
          
          # Check if any of our tags are in the operation's tags
          if (operation['tags'] & tags).any?
            operations_with_our_tags = true
            break
          end
        end
        
        # If we found operations with our tags, add the path to our filtered paths
        if operations_with_our_tags
          filtered_paths[path] = path_item
        end
      end
      
      # Replace the paths in our tag-specific spec
      tag_spec['paths'] = filtered_paths
      
      # Filter tags to only include those in our group
      tag_spec['tags'] = full_spec['tags'].select { |tag| tags.include?(tag['name']) }
      
      # Write the tag-specific spec to file
      output_file = "#{group_name.downcase}_swagger.json"
      output_file = "other_swagger.json" if group_name.downcase == 'others'
      
      File.write(tag_groups_path.join(output_file), JSON.pretty_generate(tag_spec))
    end
    
    puts 'Tag-specific swagger files generated successfully.'
  end
  
  desc 'build swagger files and create symlinks in developer-docs'
  task build_for_docs: :environment do
    # First, build the swagger files
    Rake::Task['swagger:build'].invoke
    
    # Create directories in developer-docs if they don't exist
    dev_docs_public = Rails.root.join('developer-docs', 'public')
    FileUtils.mkdir_p(File.join(dev_docs_public, 'swagger', 'tag_groups'))
    
    # Create symlinks to the swagger files
    tag_groups_path = Rails.root.join('swagger', 'tag_groups')
    
    # Symlink each JSON file
    puts 'Creating symlinks for developer-docs...'
    
    symlink_files = %w[platform_swagger.json application_swagger.json client_swagger.json other_swagger.json]
    symlink_files.each do |file|
      source = File.join(tag_groups_path, file)
      target = File.join(dev_docs_public, 'swagger', 'tag_groups', file)
      
      # Remove existing file or symlink
      FileUtils.rm_f(target)
      
      # Create a relative symbolic link
      rel_path = Pathname.new(source).relative_path_from(Pathname.new(File.dirname(target)))
      FileUtils.ln_sf(rel_path, target)
    end
    
    puts 'Symlinks created successfully.'
    puts 'You can now run the Mintlify dev server to preview the documentation.'
  end
end
