# Rails 3.0.0.beta.2+, < 3.1
if defined?(ActiveSupport) && ActiveSupport.public_methods.include?(:on_load) &&
    !Sass::Util.ap_geq?('3.1.0.beta')
  require 'sass/plugin/configuration'
  ActiveSupport.on_load(:before_configuration) do
    require 'sass'
    require 'sass/plugin'
    require 'sass/plugin/rails'
  end
end
