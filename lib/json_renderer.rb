# lib/json_renderer.rb
module JsonRenderer
  def api_call(method_name, &block)
    define_method(method_name) do |*args|
      instance_exec(*args, &block)
    rescue StandardError => e
      { error: e.message }
    end
  end
end
