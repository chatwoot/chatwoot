require 'brakeman/processors/lib/rails3_config_processor'

class Brakeman::Rails4ConfigProcessor < Brakeman::Rails3ConfigProcessor
  APPLICATION_CONFIG = s(:call, s(:call, s(:const, :Rails), :application), :configure)
  ALT_APPLICATION_CONFIG = s(:call, s(:call, s(:colon3, :Rails), :application), :configure)

  # Look for Rails.application.configure do ... end
  def process_iter exp
    if exp.block_call == APPLICATION_CONFIG or exp.block_call == ALT_APPLICATION_CONFIG
      @inside_config = true
      process exp.block if sexp? exp.block
      @inside_config = false
    else
      super
    end

    exp
  end
end
