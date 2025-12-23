AppSec WAF rules based on [appsec-event-rules](https://github.com/datadog/appsec-event-rules) builds

## How to update

> [!WARNING]
> This process is a temporary workaround to maintain compatibility with the existing code structure and will be changed.

1. Download `recommended.json` and `strict.json` of the desired version from [appsec-event-rules](https://github.com/datadog/appsec-event-rules) (example: [v1.13.3](https://github.com/DataDog/appsec-event-rules/tree/1.13.3/build))
2. Run the script below inside `waf_rules` folder to extract scanners and processors into separate files

    ```ruby
    require 'json'

    recommended_rules = JSON.parse(File.read(File.expand_path('recommended.json', __dir__)))
    strict_rules = JSON.parse(File.read(File.expand_path('strict.json', __dir__)))

    recommended_processors = recommended_rules.delete('processors')
    strict_processors = strict_rules.delete('processors')

    if recommended_processors.sort_by { |processor| processor['id'] } !=
        strict_processors.sort_by { |processor| processor['id'] }
      raise 'Processors are not the same, unable to extract them'
    end

    puts 'Extracting processors...'
    File.open(File.expand_path('processors.json', __dir__), 'wb') do |file|
      file.write(JSON.pretty_generate(recommended_processors))
    end

    recommended_scanners = recommended_rules.delete('scanners')
    strict_scanners = strict_rules.delete('scanners')

    if recommended_scanners.sort_by { |processor| processor['id'] } !=
        strict_scanners.sort_by { |processor| processor['id'] }
      raise 'Scanners are not the same, unable to extract them'
    end

    puts 'Extracting scanners...'
    File.open(File.expand_path('scanners.json', __dir__), 'wb') do |file|
      file.write(JSON.pretty_generate(recommended_scanners))
    end

    puts 'Updating rules...'

    File.open(File.expand_path('recommended.json', __dir__), 'wb') do |file|
      file.write(JSON.pretty_generate(recommended_rules))
    end

    File.open(File.expand_path('strict.json', __dir__), 'wb') do |file|
      file.write(JSON.pretty_generate(strict_rules))
    end
    ```
