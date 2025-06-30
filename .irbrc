if defined?(Rails::Console)
  # Clear the screen
  def cls
    system('clear') || system('cls')
  end

  # Reload the Rails environment
  def reload!
    puts "Reloading Rails environment..."
    ActionDispatch::Reloader.cleanup!
    ActionDispatch::Reloader.prepare!
    true
  end

  puts "Custom IRB config loaded. Type `cls` to clear and `reload!` to reload."

  Object.send(:define_method, :r!) { reload! }
end
