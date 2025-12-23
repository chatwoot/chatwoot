require 'mkmf'

if with_config('static-libstdc++')
  $LDFLAGS << ' ' << `#{CONFIG['CC']} -print-file-name=libstdc++.a`.chomp
else
  have_library('stdc++')

  case RbConfig::CONFIG['host_os']
  when /solaris(!?2.11)/
    # Do a little trickery here to enable C++ standard on Solaris 11 if found.
    # This also forces 64bit compilation mode.
    $CXX = CONFIG['CXX']
    $CXX << ' ' << '-m64'
    $CFLAGS = CONFIG['CFLAGS'].gsub(/-std=c99/, '')
    $CFLAGS << ' ' << '-m64 -std=c++11'
    $CPPFLAGS = CONFIG['CFLAGS'].gsub(/-std=c99/, '')
    $CPPFLAGS << ' ' << '-m64 -std=c++11'
    $CXXFLAGS = CONFIG['CFLAGS'].gsub(/-std=c99/, '')
    $CXXFLAGS << ' ' << '-m64 -std=c++11'
  when /aix/
    # Compiler flags necessary on AIX.
    # rubocop:disable Style/GlobalVars
    $CFLAGS << ' ' << '-D_ALL_SOURCE=1'
    $CPPFLAGS << ' ' << '-D_ALL_SOURCE=1'
    $CXXFLAGS << ' ' << '-D_ALL_SOURCE=1'
  end
end

create_makefile 'unf_ext'

unless CONFIG['CXX']
  case CONFIG['CC']
  when %r{((?:.*[-/])?)gcc([-0-9.]*)$}
    cxx = $1 + 'g++' + $2
  when %r{((?:.*[-/])?)clang([-0-9.]*)$}
    cxx = $1 + 'clang++' + $2
  else
    cxx = CONFIG['CC']
  end

  warn "CXX is automatically set to #{cxx}"

  new_mf = <<-EOF << File.read('Makefile')
CXX=#{cxx}
  EOF

  File.open('Makefile', 'w') { |mf|
    mf.print new_mf
  }
end
