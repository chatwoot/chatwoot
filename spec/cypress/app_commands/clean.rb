if defined?(DatabaseCleaner)
  # cleaning the database using database_cleaner
  DatabaseCleaner.strategy = :truncation
  DatabaseCleaner.clean
else
  logger.warn 'add database_cleaner or update cypress/app_commands/clean.rb'
  Post.delete_all if defined?(Post)
end

Rails.logger.info 'APPCLEANED' # used by log_fail.rb
