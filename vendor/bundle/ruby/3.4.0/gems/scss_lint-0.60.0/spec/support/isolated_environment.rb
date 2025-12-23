require 'fileutils'
require 'tmpdir'

shared_context 'isolated environment' do
  around do |example|
    Dir.mktmpdir do |tmpdir|
      original_home = ENV['HOME']

      begin
        virtual_home = File.expand_path(File.join(tmpdir, 'home'))
        Dir.mkdir(virtual_home)
        ENV['HOME'] = virtual_home

        working_dir = File.join(tmpdir, 'work')
        Dir.mkdir(working_dir)

        Dir.chdir(working_dir) do
          example.run
        end
      ensure
        ENV['HOME'] = original_home
      end
    end
  end
end
