require 'rake'
require 'rake/tasklib'
require 'rake/clean'
require 'ffi'
require 'tmpdir'
require 'rbconfig'
require_relative 'platform'

module FFI
  module Compiler
    DEFAULT_CFLAGS = %w(-fexceptions -O -fno-omit-frame-pointer -fno-strict-aliasing)
    DEFAULT_LDFLAGS = %w(-fexceptions)

    class CompileTask < Rake::TaskLib
      attr_reader :cflags, :cxxflags, :ldflags, :libs, :platform
      attr_accessor :name, :ext_dir, :source_dirs, :exclude

      def initialize(name)
        @name = File.basename(name)
        @ext_dir = File.dirname(name)
        @source_dirs = [@ext_dir]
        @exclude = []
        @defines = []
        @include_paths = []
        @library_paths = []
        @libraries = []
        @headers = []
        @functions = []
        @cflags = DEFAULT_CFLAGS.dup
        @cxxflags = DEFAULT_CFLAGS.dup
        @ldflags = DEFAULT_LDFLAGS.dup
        @libs = []
        @platform = Platform.system
        @exports = []

        yield self if block_given?
        define_task!
      end

      def add_include_path(path)
        @include_paths << path
      end

      def add_define(name, value=1)
        @defines << "-D#{name}=#{value}"
      end

      def have_func?(func)
        main = <<-C_FILE
        extern void #{func}();
        int main(int argc, char **argv) { #{func}(); return 0; }
        C_FILE

        if try_compile(main)
          @functions << func
          return true
        end
        false
      end

      def have_header?(header, *paths)
        try_header(header, @include_paths) || try_header(header, paths)
      end

      def have_library?(libname, *paths)
        try_library(libname, paths: @library_paths) || try_library(libname, paths: paths)
      end
      
      def have_library(lib, func = nil, headers = nil, &b)
        try_library(lib, function: func, headers: headers, paths: @library_paths)
      end
      
      def find_library(lib, func, *paths)
        try_library(lib, function: func, paths: @library_paths) || try_library(libname, function: func, paths: paths)
      end

      def export(rb_file)
        @exports << { :rb_file => rb_file, :header => File.join(@ext_dir, File.basename(rb_file).sub(/\.rb$/, '.h')) }
      end

      private
      def define_task!
        pic_flags = %w(-fPIC)
        so_flags = []

        if @platform.mac?
          pic_flags = []
          so_flags << '-bundle'

        elsif @platform.name =~ /linux/
          so_flags << "-shared -Wl,-soname,#{lib_name}"

        else
          so_flags << '-shared'
        end
        so_flags = so_flags.join(' ')

        out_dir = "#{@platform.arch}-#{@platform.os}"
        if @ext_dir != '.'
          out_dir = File.join(@ext_dir, out_dir)
        end

        directory(out_dir)
        CLOBBER.include(out_dir)

        lib_name = File.join(out_dir, Platform.system.map_library_name(@name))

        iflags = @include_paths.uniq.map { |p| "-I#{p}" }
        @defines << @functions.uniq.map { |f| "-DHAVE_#{f.upcase}=1" }
        @defines << @headers.uniq.map { |h| "-DHAVE_#{h.upcase.sub(/\./, '_')}=1" }

        cflags = (@cflags + pic_flags + iflags + @defines).join(' ')
        cxxflags = (@cxxflags + @cflags + pic_flags + iflags + @defines).join(' ')
        ld_flags = (@library_paths.map { |path| "-L#{path}" } + @ldflags).join(' ')
        libs = (@libraries.map { |l| "-l#{l}" } + @libs).join(' ')

        src_files = []
        obj_files = []
        @source_dirs.each do |dir|
          files = FileList["#{dir}/**/*.{c,cpp}"]
	  unless @exclude.empty?
	    files.delete_if { |f| f =~ Regexp.union(*@exclude) }
	  end
          src_files += files
          obj_files += files.ext('.o').map { |f| File.join(out_dir, f.sub(/^#{dir}\//, '')) }
	end

        index = 0
        src_files.each do |src|
          obj_file = obj_files[index]
          if src =~ /\.c$/
            file obj_file => [ src, File.dirname(obj_file) ] do |t|
              sh "#{cc} #{cflags} -o #{t.name} -c #{t.prerequisites[0]}"
            end

          else
            file obj_file => [ src, File.dirname(obj_file) ] do |t|
              sh "#{cxx} #{cxxflags} -o #{t.name} -c #{t.prerequisites[0]}"
            end
          end

          CLEAN.include(obj_file)
          index += 1
        end

        ld = src_files.detect { |f| f =~ /\.cpp$/ } ? cxx : cc

        # create all the directories for the output files
        obj_files.map { |f| File.dirname(f) }.sort.uniq.map { |d| directory d }

        desc "Build dynamic library"
        file lib_name => obj_files do |t|
          sh "#{ld} #{so_flags} -o #{t.name} #{t.prerequisites.join(' ')} #{ld_flags} #{libs}"
        end
        CLEAN.include(lib_name)

        @exports.each do |e|
          desc "Export #{e[:rb_file]}"
          file e[:header] => [ e[:rb_file] ] do |t|
            ruby "-I#{File.join(File.dirname(__FILE__), 'fake_ffi')} -I#{File.dirname(t.prerequisites[0])} #{File.join(File.dirname(__FILE__), 'exporter.rb')} #{t.prerequisites[0]} #{t.name}"
          end

          obj_files.each { |o| file o  => [ e[:header] ] }
          CLEAN.include(e[:header])

          desc "Export API headers"
          task :api_headers => [ e[:header] ]
        end

        task :default => [ lib_name ]
        task :package => [ :api_headers ]
      end

      def try_header(header, paths)
        main = <<-C_FILE
          #include <#{header}>
          int main(int argc, char **argv) { return 0; }
        C_FILE

        if paths.empty? && try_compile(main)
          @headers << header
          return true
        end

        paths.each do |path|
          if try_compile(main, "-I#{path}")
            @include_paths << path
            @headers << header
            return true
          end
        end
        false
      end


      def try_library(libname, options = {})
        func = options[:function] || 'main'
        paths = options[:paths] || ''
        main = <<-C_FILE
        #{(options[:headers] || []).map {|h| "#include <#{h}>"}.join('\n')}
        extern int #{func}();
        int main() { return #{func}(); }
        C_FILE

        if paths.empty? && try_compile(main)
          @libraries << libname
          return true
        end

        paths.each do |path|
          if try_compile(main, "-L#{path}", "-l#{libname}")
            @library_paths << path
            @libraries << libname
          end
        end
      end

      def try_compile(src, *opts)
        Dir.mktmpdir do |dir|
          path = File.join(dir, 'ffi-test.c')
          File.open(path, 'w') do |f|
            f << src
          end
          cflags = opts.join(' ')
          output = File.join(dir, 'ffi-test')
          begin
            return system "#{cc} #{cflags} -o #{output} -c #{path} > #{path}.log 2>&1"
          rescue
            return false
          end
        end
      end

      def cc
        @cc ||= (ENV['CC'] || RbConfig::CONFIG['CC'] || 'cc')
      end

      def cxx
        @cxx ||= (ENV['CXX'] || RbConfig::CONFIG['CXX'] || 'c++')
      end
    end
  end
end
