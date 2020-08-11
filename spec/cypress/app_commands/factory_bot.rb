Array.wrap(command_options).map do |factory_options|
  factory_method = factory_options.shift
  begin
    logger.debug "running #{factory_method}, #{factory_options}"
    CypressOnRails::SmartFactoryWrapper.public_send(factory_method, *factory_options)
  rescue StandardError => e
    logger.error "#{e.class}: #{e.message}"
    logger.error e.backtrace.join("\n")
    logger.error e.record.inspect.to_s if e.is_a?(ActiveRecord::RecordInvalid)
    raise e
  end
end
