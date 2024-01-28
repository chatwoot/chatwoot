namespace :assets do
  return unless Rake::Task.task_defined?('assets:precompile')

  Rake::Task['assets:precompile'].enhance do
    # Your custom Yarn workspace SDK build command

    raise 'client-apps/** build failed. See output above for errors.' unless system('yarn workspace @chatwoot/sdk build')

    puts 'client-apps/** build completed successfully.'

    # Define your source and destination directories
    source_dir = 'client-apps/sdk/dist/sdk.js'
    destination_dir = 'public/packs/js'

    # Use FileUtils to copy the build directory to the desired location
    require 'fileutils'
    FileUtils.cp_r source_dir, destination_dir, verbose: true
    puts "Build folder copied to #{destination_dir}."
  end
end
