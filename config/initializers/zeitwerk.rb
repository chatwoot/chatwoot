Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "ee" => "EE"
  )
end
