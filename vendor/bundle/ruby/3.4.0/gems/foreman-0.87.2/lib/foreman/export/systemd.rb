require "erb"
require "foreman/export"

class Foreman::Export::Systemd < Foreman::Export::Base

  def export
    super

    Dir["#{location}/#{app}*.target"]
      .concat(Dir["#{location}/#{app}*.service"])
      .concat(Dir["#{location}/#{app}*.target.wants/#{app}*.service"])
      .each do |file|
      clean file
    end

    Dir["#{location}/#{app}*.target.wants"].each do |file|
      clean_dir file
    end

    service_names = []

    engine.each_process do |name, process|
      1.upto(engine.formation[name]) do |num|
        port = engine.port_for(process, num)
        process_name = "#{name}.#{num}"
        service_filename = "#{app}-#{process_name}.service"
        write_template "systemd/process.service.erb", service_filename, binding
        service_names << service_filename
      end
    end

    write_template "systemd/master.target.erb", "#{app}.target", binding
  end
end
