require "erb"
require "foreman/export"

class Foreman::Export::Runit < Foreman::Export::Base

  ENV_VARIABLE_REGEX = /([a-zA-Z_]+[a-zA-Z0-9_]*)=(\S+)/

  def export
    super

    engine.each_process do |name, process|
      1.upto(engine.formation[name]) do |num|
        process_directory = "#{app}-#{name}-#{num}"

        create_directory process_directory
        create_directory "#{process_directory}/env"
        create_directory "#{process_directory}/log"

        write_template "runit/run.erb", "#{process_directory}/run", binding
        chmod 0755, "#{process_directory}/run"

        port = engine.port_for(process, num)
        engine.env.merge("PORT" => port.to_s).each do |key, value|
          write_file "#{process_directory}/env/#{key}", value
        end

        write_template "runit/log/run.erb", "#{process_directory}/log/run", binding
        chmod 0755, "#{process_directory}/log/run"
      end
    end

  end

end
