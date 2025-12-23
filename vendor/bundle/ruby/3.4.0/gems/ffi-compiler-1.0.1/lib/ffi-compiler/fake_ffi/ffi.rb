module FFI

  def self.exporter=(exporter)
    @@exporter = exporter
  end

  def self.exporter
    @@exporter ||= Exporter.new(nil)
  end

  class Type
    attr_reader :name
    def initialize(name)
      @name = name
    end
  end
  
  class StructByReference < Type
    def initialize(struct_class)
      super("struct #{struct_class.to_s.gsub('::', '_')} *")
    end
  end

  class StructByValue < Type
    def initialize(struct_class)
      super("struct #{struct_class.to_s.gsub('::', '_')}")
    end
  end

  class CallbackInfo
    attr_reader :return_type
    attr_reader :arg_types
    attr_reader :options

    def initialize(return_type, arg_types = [], *other)
      @return_type = return_type
      @arg_types = arg_types
      @options = options
    end

    def name(name)
      params = @arg_types.empty? ? 'void' : @arg_types.map(&:name).join(', ')
      "#{@return_type.name} (*#{name})(#{params})"
    end
  end

  PrimitiveTypes = {
      :void => 'void',
      :bool => 'bool',
      :string => 'const char *',
      :char => 'char',
      :uchar => 'unsigned char',
      :short => 'short',
      :ushort => 'unsigned short',
      :int => 'int',
      :uint => 'unsigned int',
      :long => 'long',
      :ulong => 'unsigned long',
      :long_long => 'long long',
      :ulong_long => 'unsigned long long',
      :float => 'float',
      :double => 'double',
      :long_double => 'long double',
      :pointer => 'void *',
      :int8 => 'int8_t',
      :uint8 => 'uint8_t',
      :int16 => 'int16_t',
      :uint16 => 'uint16_t',
      :int32 => 'int32_t',
      :uint32 => 'uint32_t',
      :int64 => 'int64_t',
      :uint64 => 'uint64_t',
      :buffer_in => 'const in void *',
      :buffer_out => 'out void *',
      :buffer_inout => 'inout void *',
      :varargs => '...'
  }

  TypeMap = {}
  def self.find_type(type)
    return type if type.is_a?(Type) or type.is_a?(CallbackInfo)

    t = TypeMap[type]
    return t unless t.nil?

    if PrimitiveTypes.has_key?(type)
      return TypeMap[type] = Type.new(PrimitiveTypes[type])
    end
    raise TypeError.new("cannot resolve type #{type}")
  end

  class Function
    def initialize(*args)
    end
  end

  class Exporter
    attr_accessor :mod
    attr_reader :functions, :callbacks, :structs

    def initialize(mod)
      @mod = mod
      @functions = []
      @callbacks = {}
      @structs = []
    end

    def attach(mname, fname, result_type, param_types)
      @functions << { mname: mname, fname: fname, result_type: result_type, params: param_types.dup }
    end
    
    def struct(name, fields)
      @structs << { name: name, fields: fields.dup }
    end

    def callback(name, cb)
      @callbacks[name] = cb
    end

    def dump(out_file)
      File.open(out_file, 'w') do |f|
        guard = File.basename(out_file).upcase.gsub('.', '_').gsub('/', '_')
        f.puts <<-HEADER
#ifndef #{guard}
#define #{guard} 1

#ifndef RBFFI_EXPORT
# ifdef __cplusplus
#  define RBFFI_EXPORT extern "C"
# else
#  define RBFFI_EXPORT
# endif
#endif

        HEADER

        @callbacks.each do |name, cb|
          f.puts "typedef #{cb.name(name)};"
        end
        @structs.each do |s|
          f.puts "struct #{s[:name].gsub('::', '_')} {"
          s[:fields].each do |field|
            if field[:type].is_a?(CallbackInfo)
              type = field[:type].name(field[:name].to_s)
            else
              type = "#{field[:type].name} #{field[:name].to_s}"
            end
            f.puts "#{' ' * 4}#{type};"
          end
          f.puts '};'
          f.puts
        end
        @functions.each do |fn|
          param_string = fn[:params].empty? ? 'void' : fn[:params].map(&:name).join(', ')
          f.puts "RBFFI_EXPORT #{fn[:result_type].name} #{fn[:fname]}(#{param_string});"
        end
        f.puts <<-EPILOG

#endif /* #{guard} */
        EPILOG
      end
    end
    
  end

  module Library
    def self.extended(mod)
      FFI.exporter.mod = mod
    end

    def attach_function(name, func, args, returns = nil, options = nil)
      mname, a2, a3, a4, a5 = name, func, args, returns, options
      cname, arg_types, ret_type, opts = (a4 && (a2.is_a?(String) || a2.is_a?(Symbol))) ? [ a2, a3, a4, a5 ] : [ mname.to_s, a2, a3, a4 ]
      arg_types = arg_types.map { |e| find_type(e) }
      FFI.exporter.attach(mname, cname, find_type(ret_type), arg_types)
    end

    def ffi_lib(*args)

    end

    def callback(*args)
      name, params, ret = if args.length == 3
        args
      else
        [ nil, args[0], args[1] ]
      end
      native_params = params.map { |e| find_type(e) }
      cb = FFI::CallbackInfo.new(find_type(ret), native_params)
      FFI.exporter.callback(name, cb) if name
    end

    TypeMap = {}
    def find_type(type)
      t = TypeMap[type]
      return t unless t.nil?
      
      if type.is_a?(Class) && type < Struct
        return TypeMap[type] = StructByReference.new(type)
      end

      TypeMap[type] = FFI.find_type(type)
    end
  end

  class Struct
    def self.layout(*args)
      return if args.size.zero?
      fields = []
      if args.first.kind_of?(Hash)
        args.first.each do |name, type|
          fields << { :name => name, :type => find_type(type), :offset => nil }
        end
      else
        i = 0
        while i < args.size
          name, type, offset = args[i], args[i+1], nil
          i += 2
          if args[i].kind_of?(Integer)
            offset = args[i]
            i += 1
          end
          fields << { :name => name, :type => find_type(type), :offset => offset }
        end
      end
      FFI.exporter.struct(self.to_s, fields)
    end

    def initialize
      @data = {}
    end

    def [](name)
      @data[name]
    end

    def []=(name, value)
      @data[name] = value
    end

    def self.callback(params, ret)
      FFI::CallbackInfo.new(find_type(ret), params.map { |e| find_type(e) })
    end

    TypeMap = {}
    def self.find_type(type)
      t = TypeMap[type]
      return t unless t.nil?

      if type.is_a?(Class) && type < Struct
        return TypeMap[type] = StructByValue.new(type)
      end

      TypeMap[type] = FFI.find_type(type)
    end

    def self.in
      ptr(:in)
    end

    def self.out
      ptr(:out)
    end

    def self.ptr(flags = :inout)
      StructByReference.new(self)
    end

    def self.val
      StructByValue.new(self)
    end

    def self.by_value
      self.val
    end

    def self.by_ref(flags = :inout)
      self.ptr(flags)
    end

  end
end