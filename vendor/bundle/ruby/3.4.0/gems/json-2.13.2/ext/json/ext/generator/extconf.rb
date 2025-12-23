require 'mkmf'

if RUBY_ENGINE == 'truffleruby'
  # The pure-Ruby generator is faster on TruffleRuby, so skip compiling the generator extension
  File.write('Makefile', dummy_makefile("").join)
else
  append_cflags("-std=c99")
  $defs << "-DJSON_GENERATOR"
  $defs << "-DJSON_DEBUG" if ENV["JSON_DEBUG"]

  if enable_config('generator-use-simd', default=!ENV["JSON_DISABLE_SIMD"])
    load __dir__ + "/../simd/conf.rb"
  end

  create_makefile 'json/ext/generator'
end
