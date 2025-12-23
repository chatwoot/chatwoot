# Fake filters for Slim
module Slim
  class Embedded
    class TiltEngine
      def on_slim_embedded(engine, body, attrs)
        # Override this method to avoid Slim trying to load sass/scss and failing
        case engine
        when :sass, :scss, :coffee
          tilt_engine = nil # Doesn't really matter, ignored below
        else
          # Original Slim code
          tilt_engine = Tilt[engine] || raise(Temple::FilterError, "Tilt engine #{engine} is not available.")
        end

        tilt_options = options[engine.to_sym] || {}
        tilt_options[:default_encoding] ||= 'utf-8'

        [:multi, tilt_render(tilt_engine, tilt_options, collect_text(body)), collect_newlines(body)]
      end
    end

    class SassEngine
      protected

      def tilt_render(tilt_engine, tilt_options, text)
        [:dynamic,
         "BrakemanFilter.render(#{text.inspect}, #{self.class})"]
      end
    end

    class CoffeeEngine < TiltEngine
      protected

      def tilt_render(tilt_engine, tilt_options, text)
        [:dynamic,
         "BrakemanFilter.render(#{text.inspect}, #{self.class})"]
      end
    end

    # Override the engine for CoffeeScript, because Slim doesn't have
    # one, it just uses Tilt's
    register :coffee, JavaScriptEngine, engine: CoffeeEngine
  end
end
