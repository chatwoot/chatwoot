Around do |scenario, block|
  DatabaseCleaner.cleaning(&block)
end
