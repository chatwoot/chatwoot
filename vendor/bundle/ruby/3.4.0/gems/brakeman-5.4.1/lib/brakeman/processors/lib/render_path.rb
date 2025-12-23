module Brakeman
  class RenderPath
    attr_reader :path

    def initialize
      @path = []
    end

    def add_controller_render controller_name, method_name, line, file
      method_name ||= ""

      @path << { :type => :controller,
                 :class => controller_name.to_sym,
                 :method => method_name.to_sym,
                 :line => line,
                 :file => file
                }

      self
    end

    def add_template_render template_name, line, file
      @path << { :type => :template,
                 :name => template_name.to_sym,
                 :line => line,
                 :file => file
               }

      self
    end

    def last_template= template
      if @path.last
        @path.last[:rendered] = {
          name: template.name,
          file: template.file,
        }
      else
        Brakeman.debug "[Notice] No render path to add template information"
      end
    end

    def include_template? name
      name = name.to_sym

      @path.any? do |loc|
        loc[:type] == :template and loc[:name] == name
      end
    end

    def include_controller? klass
      klass = klass.to_sym

      @path.any? do |loc|
        loc[:type] == :controller and loc[:class] == klass
      end
    end

    def include_any_method? method_names
      names = method_names.map(&:to_sym)

      @path.any? do |loc|
        loc[:type] == :controller and names.include? loc[:method]
      end
    end

    def rendered_from_controller?
      @path.any? do |loc|
        loc[:type] == :controller
      end
    end

    def each &block
      @path.each(&block)
    end

    def join *args
      self.to_a.join(*args)
    end

    def length
      @path.length
    end

    def map &block
      @path.map(&block)
    end

    def to_a
      @path.map do |loc|
        case loc[:type]
        when :template
          "Template:#{loc[:name]}"
        when :controller
          "#{loc[:class]}##{loc[:method]}"
        end
      end
    end

    def last
      self.to_a.last
    end

    def to_s
      self.to_a.to_s
    end

    def to_sym
      self.to_s.to_sym
    end

    def to_json *args
      require 'json'
      JSON.generate(@path)
    end

    def with_relative_paths
      @path.map do |loc|
        r = loc.dup

        if r[:file]
          r[:file] = r[:file].relative
        end

        if r[:rendered] and r[:rendered][:file]
          r[:rendered] = r[:rendered].dup
          r[:rendered][:file] = r[:rendered][:file].relative
        end

        r
      end
    end

    def initialize_copy original
      @path = original.path.dup
      self
    end
  end
end
