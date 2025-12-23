require 'rake'
require 'rake/tasklib'
require 'rake/clean'

module FFI
  module Compiler
    class ExportTask < Rake::TaskLib

      def initialize(rb_dir, out_dir, options = {})
        @rb_dir = rb_dir
        @out_dir = out_dir
        @gem_spec = options[:gem_spec]
        @exports = []
        
        if block_given?
          yield self
          define_tasks!
        end
      end

      def export(rb_file)
        @exports << { :rb_file => File.join(@rb_dir, rb_file), :header => File.join(@out_dir, File.basename(rb_file).sub(/\.rb$/, '.h')) }
      end

      def export_all
        Dir["#@rb_dir/**/*rb"].each do |rb_file|
          @exports << { :rb_file => rb_file, :header => File.join(@out_dir, File.basename(rb_file).sub(/\.rb$/, '.h')) }
        end
      end

      private
      def define_tasks!
        @exports.each do |e|
          file e[:header] => [ e[:rb_file] ] do |t|
            ruby "-I#{File.join(File.dirname(__FILE__), 'fake_ffi')} #{File.join(File.dirname(__FILE__), 'exporter.rb')} #{t.prerequisites[0]} #{t.name}"
          end
          CLEAN.include(e[:header])

          desc "Export API headers"
          task :api_headers => [ e[:header] ]
          @gem_spec.files << e[:header] unless @gem_spec.nil?
        end

        task :gem => [ :api_headers ] unless @gem_spec.nil?
      end

    end
  end
end
