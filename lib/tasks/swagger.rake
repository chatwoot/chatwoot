namespace :swagger do
  desc 'build combined swagger.json file from all the fragmented definitions and paths inside swagger folder'
  task build: :environment do
    require 'json_refs'

    Dir.chdir(Rails.root.join('swagger')) do
      swagger_index = YAML.safe_load(File.open('index.yml'))

      final_build = JsonRefs.call(
        swagger_index,
        resolve_local_ref: false,
        resolve_file_ref: true,
        logging: true
      )
      File.write('swagger.json', JSON.pretty_generate(final_build))
      puts 'Swagger build was succesful.'
      puts 'Generated', Rails.root.join('swagger/swagger.json')
      puts 'Go to http://localhost:3000/swagger see the changes.'
    end
  end
end
