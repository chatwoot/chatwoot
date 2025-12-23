# encoding: UTF-8

class PryRails::ShowModel < Pry::ClassCommand
  match "show-model"
  group "Rails"
  description "Show the given model."

  def options(opt)
    opt.banner unindent <<-USAGE
      Usage: show-model <model name>

      show-model displays one model from the current Rails app.
    USAGE
  end

  def process
    Rails.application.eager_load!

    if args.empty?
      output.puts opts
      return
    end

    begin
      model = Object.const_get(args.first)
    rescue NameError
      output.puts "Couldn't find model #{args.first}!"
      return
    end

    formatter = PryRails::ModelFormatter.new

    case
    when defined?(ActiveRecord::Base) && model < ActiveRecord::Base
      output.puts formatter.format_active_record(model)
    when defined?(Mongoid::Document) && model < Mongoid::Document
      output.puts formatter.format_mongoid(model)
    else
      output.puts "Don't know how to show #{model}!"
    end
  end
end

PryRails::Commands.add_command PryRails::ShowModel
