module FFI::Compiler
  class Platform
    LIBSUFFIX = FFI::Platform.mac? ? 'bundle' : FFI::Platform::LIBSUFFIX
    
    def self.system
      @@system ||= Platform.new
    end
    
    def map_library_name(name)
      "#{FFI::Platform::LIBPREFIX}#{name}.#{LIBSUFFIX}"
    end
    
    def arch
      FFI::Platform::ARCH
    end
    
    def os
      FFI::Platform::OS
    end
    
    def name
      FFI::Platform.name
    end
    
    def mac?
      FFI::Platform.mac?
    end
  end
end