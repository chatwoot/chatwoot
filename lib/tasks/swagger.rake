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
    end
  end
end
