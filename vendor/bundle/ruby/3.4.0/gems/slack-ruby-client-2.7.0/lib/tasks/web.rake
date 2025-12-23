# frozen_string_literal: true

require 'json-schema'
require 'erubis'
require 'active_support'
require 'active_support/core_ext'

# largely from https://github.com/aki017/slack-ruby-gem
namespace :slack do
  namespace :web do
    namespace :api do
      desc 'Update Web API.'
      task update: [:git_update] do
        group_schema = JSON.parse(File.read('lib/slack/web/api/schema/group.json'))
        dirglob = 'lib/slack/web/api/slack-api-ref/groups/**/*.json'
        groups = Dir.glob(dirglob).each_with_object({}) do |path, result|
          name = File.basename(path, '.json')
          parsed = JSON.parse(File.read(path))
          parsed['undocumented'] = true if path =~ /undocumented/
          JSON::Validator.validate(group_schema, parsed, insert_defaults: true)
          result[name] = parsed
        end

        method_schema = JSON.parse(File.read('lib/slack/web/api/schema/method.json'))
        data = [
          Dir.glob('lib/slack/web/api/slack-api-ref/methods/**/*.json'),
          Dir.glob('lib/slack/web/api/mixins/**/*.json')
        ].flatten.each_with_object({}) do |path, result|
          file_name = File.basename(path, '.json')
          prefix = file_name.split('.')[0..-2].join('.')
          name = file_name.split('.')[-1]
          result[prefix] ||= {}
          parsed = JSON.parse(File.read(path))
          parsed['undocumented'] = true if path =~ /undocumented/
          JSON::Validator.validate(method_schema, parsed, insert_defaults: true)
          if parsed['deprecated'] && parsed['deprecation']['deprecation_warning'] =~ /It will stop functioning in February 2021/
            next
          end

          result[prefix][name] = parsed
        end

        # Start with a fresh slate
        Dir.glob('lib/slack/web/api/endpoints/*.rb').each { |file| File.delete(file) }
        Dir.glob('spec/slack/web/api/endpoints/*_spec.rb').each { |file| File.delete(file) }
        Dir.glob('bin/commands/*.rb').each { |file| File.delete(file) }

        method_template = Erubis::Eruby.new(File.read('lib/slack/web/api/templates/method.erb'))
        method_spec_template =
          Erubis::Eruby.new(File.read('lib/slack/web/api/templates/method_spec.erb'))
        command_template = Erubis::Eruby.new(File.read('lib/slack/web/api/templates/command.erb'))

        data.each.with_index(1) do |(group, names), index|
          printf "%2d/%2d %10s %s\n", index, data.size, group, names.keys
          # method
          snaked_group = group.tr('.', '_')
          rendered_method = method_template.result(group: group, names: names)
          File.write "lib/slack/web/api/endpoints/#{snaked_group}.rb", rendered_method
          rendered_method_spec = method_spec_template.result(group: group, names: names)
          File.write "spec/slack/web/api/endpoints/#{snaked_group}_spec.rb", rendered_method_spec

          unless ENV.key?('SKIP_PATCH')
            Dir.glob("lib/slack/web/api/patches/#{group}*.patch").sort.each do |patch|
              puts "- patching #{patch}"
              system("git apply #{patch}") || raise('failed to apply patch')
            end
          end

          # command
          raise "Missing group #{group}" unless groups.key?(group)

          rendered_command = command_template.result(group: groups[group], names: names)
          File.write "bin/commands/#{snaked_group}.rb", rendered_command
        end

        endpoints_template =
          Erubis::Eruby.new(File.read('lib/slack/web/api/templates/endpoints.erb'))
        File.write(
          'lib/slack/web/api/endpoints.rb',
          endpoints_template.result(files: data.keys.map { |key| key.tr('.', '_') })
        )

        errors_template = Erubis::Eruby.new(File.read('lib/slack/web/api/templates/errors.erb'))
        errors = data.values.map do |names|
          names.values.map do |d|
            d['errors'].keys
          end
        end.flatten.compact.uniq.sort
        rendered_errors = errors_template.result(errors: errors)
        File.write('lib/slack/web/api/errors.rb', rendered_errors)
      end
    end
  end
end
