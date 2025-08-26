require 'json_refs'
require 'fileutils'
require 'pathname'
require 'yaml'
require 'json'

module SwaggerTaskActions
  def self.execute_build
    swagger_dir = Rails.root.join('swagger')
    # Paths relative to swagger_dir for use within Dir.chdir
    index_yml_relative_path = 'index.yml'
    swagger_json_relative_path = 'swagger.json'

    Dir.chdir(swagger_dir) do
      # Operations within this block are relative to swagger_dir
      swagger_index_content = File.read(index_yml_relative_path)
      swagger_index = YAML.safe_load(swagger_index_content)

      final_build = JsonRefs.call(
        swagger_index,
        resolve_local_ref: false,
        resolve_file_ref: true, # Uses CWD (swagger_dir) for resolving file refs
        logging: true
      )
      File.write(swagger_json_relative_path, JSON.pretty_generate(final_build))

      # For user messages, provide the absolute path
      absolute_swagger_json_path = swagger_dir.join(swagger_json_relative_path)
      puts 'Swagger build was successful.'
      puts "Generated #{absolute_swagger_json_path}"
      puts 'Go to http://localhost:3000/swagger see the changes.'

      # Trigger dependent task
      Rake::Task['swagger:build_tag_groups'].invoke
    end
  end

  def self.execute_build_tag_groups
    base_swagger_path = Rails.root.join('swagger')
    tag_groups_output_dir = base_swagger_path.join('tag_groups')
    full_spec_path = base_swagger_path.join('swagger.json')
    index_yml_path = base_swagger_path.join('index.yml')

    full_spec = JSON.parse(File.read(full_spec_path))
    swagger_index = YAML.safe_load(File.read(index_yml_path))
    tag_groups = swagger_index['x-tagGroups']

    FileUtils.mkdir_p(tag_groups_output_dir)

    tag_groups.each do |tag_group|
      _process_tag_group(tag_group, full_spec, tag_groups_output_dir)
    end

    puts 'Tag-specific swagger files generated successfully.'
  end

  def self.execute_build_for_docs
    Rake::Task['swagger:build'].invoke # Ensure all swagger files are built first

    developer_docs_public_path = Rails.root.join('developer-docs/public')
    tag_groups_in_dev_docs_path = developer_docs_public_path.join('swagger/tag_groups')
    source_tag_groups_path = Rails.root.join('swagger/tag_groups')

    FileUtils.mkdir_p(tag_groups_in_dev_docs_path)
    puts 'Creating symlinks for developer-docs...'

    symlink_files = %w[platform_swagger.json application_swagger.json client_swagger.json other_swagger.json]
    symlink_files.each do |file|
      _create_symlink(source_tag_groups_path.join(file), tag_groups_in_dev_docs_path.join(file))
    end

    puts 'Symlinks created successfully.'
    puts 'You can now run the Mintlify dev server to preview the documentation.'
  end

  # Private helper methods
  class << self
    private

    def _process_tag_group(tag_group, full_spec, output_dir)
      group_name = tag_group['name']
      tags_in_current_group = tag_group['tags']

      tag_spec = JSON.parse(JSON.generate(full_spec)) # Deep clone

      tag_spec['paths'] = _filter_paths_for_tag_group(tag_spec['paths'], tags_in_current_group)
      tag_spec['tags'] = _filter_tags_for_tag_group(tag_spec['tags'], tags_in_current_group)

      output_filename = _determine_output_filename(group_name)
      File.write(output_dir.join(output_filename), JSON.pretty_generate(tag_spec))
    end

    def _operation_has_matching_tags?(operation, tags_in_group)
      return false unless operation.is_a?(Hash)

      operation_tags = operation['tags']
      return false unless operation_tags.is_a?(Array)

      operation_tags.intersect?(tags_in_group)
    end

    def _filter_paths_for_tag_group(paths_spec, tags_in_group)
      (paths_spec || {}).filter_map do |path, path_item|
        next unless path_item.is_a?(Hash)

        operations_with_group_tags = path_item.any? do |_method, operation|
          _operation_has_matching_tags?(operation, tags_in_group)
        end
        [path, path_item] if operations_with_group_tags
      end.to_h
    end

    def _filter_tags_for_tag_group(tags_spec, tags_in_group)
      if tags_spec.is_a?(Array)
        tags_spec.select { |tag_definition| tags_in_group.include?(tag_definition['name']) }
      else
        []
      end
    end

    def _determine_output_filename(group_name)
      return 'other_swagger.json' if group_name.casecmp('others').zero?

      sanitized_group_name = group_name.downcase.tr(' ', '_').gsub(/[^a-z0-9_]+/, '')
      "#{sanitized_group_name}_swagger.json"
    end

    def _create_symlink(source_file_path, target_file_path)
      FileUtils.rm_f(target_file_path) # Remove existing to avoid errors

      if File.exist?(source_file_path)
        relative_source_path = Pathname.new(source_file_path).relative_path_from(target_file_path.dirname)
        FileUtils.ln_sf(relative_source_path, target_file_path)
      else
        puts "Warning: Source file #{source_file_path} not found. Skipping symlink for #{File.basename(target_file_path)}."
      end
    end
  end
end

namespace :swagger do
  desc 'build combined swagger.json file from all the fragmented definitions and paths inside swagger folder'
  task build: :environment do
    SwaggerTaskActions.execute_build
  end

  desc 'build separate swagger files for each tag group'
  task build_tag_groups: :environment do
    SwaggerTaskActions.execute_build_tag_groups
  end

  desc 'build swagger files and create symlinks in developer-docs'
  task build_for_docs: :environment do
    SwaggerTaskActions.execute_build_for_docs
  end
end
