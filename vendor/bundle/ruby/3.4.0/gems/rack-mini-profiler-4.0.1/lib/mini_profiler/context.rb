# frozen_string_literal: true

class Rack::MiniProfiler::Context
  attr_accessor :inject_js, :current_timer, :page_struct, :skip_backtrace,
                :full_backtrace, :discard, :mpt_init, :measure

  def initialize(opts = {})
    opts["measure"] = true unless opts.key? "measure"
    opts.each do |k, v|
      self.instance_variable_set('@' + k, v)
    end
  end

end
