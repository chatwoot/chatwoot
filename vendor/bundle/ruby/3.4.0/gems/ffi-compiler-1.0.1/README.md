
[ffi-compiler](https://github.com/ffi/ffi-compiler) is a ruby library for automating compilation of native libraries for use with [ffi](https://github.com/ffi/ffi)

To use, define your own ruby->native API using ffi, implement it in C, then use ffi-compiler to compile it.

Example
------
	
###### Directory layout
	lib
	  |- example
	      |- example.rb
	      
	ext
      |- example.c
      |- Rakefile
      
    example.gemspec

###### lib/example/example.rb
	require 'ffi'
	require 'ffi-compiler/loader'
	
	module Example
	  extend FFI::Library
	  ffi_lib FFI::Compiler::Loader.find('example')
	  
	  # example function which takes no parameters and returns long
	  attach_function :example, [], :long
	end

###### ext/example.c
	long
	example(void)
	{
	    return 0xdeadbeef;
	}

###### ext/Rakefile
	require 'ffi-compiler/compile_task'
	
	FFI::Compiler::CompileTask.new('example') do |c|
	  c.have_header?('stdio.h', '/usr/local/include')
	  c.have_func?('puts')
	  c.have_library?('z')
	end

###### example.gemspec
	Gem::Specification.new do |s|
      s.extensions << 'ext/Rakefile'
	  s.name = 'example'
	  s.version = '0.0.1'
	  s.email = 'ffi-example'
	  s.files = %w(example.gemspec) + Dir.glob("{lib,spec,ext}/**/*")
	  s.add_dependency 'rake'
	  s.add_dependency 'ffi-compiler'
	end
    
###### Build gem and install it
	gem build example.gemspec && gem install example-0.0.1.gem
	Successfully built RubyGem
	  Name: example
	  Version: 0.0.1
	  File: example-0.0.1.gem
	Building native extensions.  This could take a while...
	Successfully installed example-0.0.1

###### Test it
	$ irb
	2.0.0dev :001 > require 'example/example'
	 => true 
	2.0.0dev :002 > puts "Example.example=#{Example.example.to_s(16)}"
	Example.example=deadbeef
	 => nil 
