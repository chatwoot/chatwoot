# frozen_string_literal: true

require 'json-schema'
require 'erubis'

# largely from https://github.com/aki017/slack-ruby-gem
namespace :slack do
  namespace :real_time do
    namespace :api do
      REAL_TIME_EVENTS_MARKER = '### RealTime Events'

      desc 'Update Real Time API.'
      task update: [:git_update] do
        event_schema = JSON.parse(File.read('lib/slack/real_time/api/schema/event.json'))
        dirglob = 'lib/slack/web/api/slack-api-ref/events/**/*.json'
        events = Dir.glob(dirglob).each_with_object({}) do |path, result|
          name = File.basename(path, '.json')
          parsed = JSON.parse(File.read(path))
          JSON::Validator.validate(event_schema, parsed, insert_defaults: true)
          next if name == 'message'

          result[name] = parsed
        end

        hook_template = Erubis::Eruby.new(File.read('lib/slack/real_time/api/templates/event_handler.erb'))
        Dir.glob('lib/slack/real_time/stores/**/*.rb').each do |store_file|
          next if File.basename(store_file) == 'base.rb'

          STDOUT.write "#{File.basename(store_file)}: "

          store_file_contents = File.read(store_file)

          unless store_file_contents.include?(REAL_TIME_EVENTS_MARKER)
            puts "missing '#{REAL_TIME_EVENTS_MARKER}' line; skipping."
            next
          end

          # Extract current hook implementations from the store class
          hooks = {}
          hook_matcher = /
            (?:^[[:blank:]]*\R)+                                                     # At least one blank line
            (?:^[[:blank:]]*\#.*\R)*                                                 # Optional preceding comments
            (?<hook>                                                                 # on :event do |data|
              ^(?<padding>[[:blank:]]+)\#\ *on\ :(?<event>\w+)\ do\ \|[\w, ]+\|\ *\R # Commented hook
              (?>^\k<padding>\#.*\R)*                                                # Extra comments
              |
              ^(?<padding>[[:blank:]]+)on\ :(?<event>\w+)\ do\ \|[\w, ]+\|\ *\R      # Active hook
              [\s\S]*?                                                               # Inside block
              (?>^\k<padding>end[[:blank:]]*\R)                                      # End of block
            )
          /x
          store_file_contents.gsub!(hook_matcher) do
            hook, event = Regexp.last_match.values_at(:hook, :event)
            hooks[event] = hook
            nil
          end

          # Render latest event documentation with current hook implementations
          rendered_hooks = events.sort.map do |event_name, event_data|
            STDOUT.write(hooks.key?(event_name) ? '.' : 'x')

            hook_template.result(
              name: event_data['name'],
              desc: event_data['desc'],
              hook: hooks[event_name]
            ).rstrip
          end

          # Insert updated event hooks under RealTime Events marker
          store_file_contents.gsub!(
            REAL_TIME_EVENTS_MARKER,
            [REAL_TIME_EVENTS_MARKER, *rendered_hooks].join("\n\n")
          )
          File.write(store_file, store_file_contents)

          puts ' done.'
        end
      end
    end
  end
end
