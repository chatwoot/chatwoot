# We are hooking config loader to run automatically everytime migration is executed
Rake::Task['db:migrate'].enhance do
  puts 'Loading Installation config'
  ConfigLoader.new.process
end
