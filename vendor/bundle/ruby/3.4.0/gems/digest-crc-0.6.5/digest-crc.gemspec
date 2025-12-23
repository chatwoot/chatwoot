# encoding: utf-8

require 'yaml'

Gem::Specification.new do |gem|
  gemspec = YAML.load_file('gemspec.yml')

  gem.name    = gemspec.fetch('name')
  gem.version = gemspec.fetch('version') do
                  lib_dir = File.join(File.dirname(__FILE__),'lib')
                  $LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)

                  require 'digest/crc/version'
                  Digest::CRC::VERSION
                end

  gem.summary     = gemspec['summary']
  gem.description = gemspec['description']
  gem.licenses    = Array(gemspec['license'])
  gem.authors     = Array(gemspec['authors'])
  gem.email       = gemspec['email']
  gem.homepage    = gemspec['homepage']
  gem.metadata    = gemspec['metadata'] if gemspec['metadata']

  glob = lambda { |patterns| gem.files & Dir[*patterns] }

  gem.files = `git ls-files`.split($/)
  gem.files = glob[gemspec['files']] if gemspec['files']

  gem.executables = gemspec.fetch('executables') do
    glob['bin/*'].map { |path| File.basename(path) }
  end
  gem.default_executable = gem.executables.first if Gem::VERSION < '1.7.'

  gem.extensions       = glob[gemspec['extensions'] || 'ext/**/extconf.rb']
  gem.test_files       = glob[gemspec['test_files'] || '{test/{**/}*_test.rb']
  gem.extra_rdoc_files = glob[gemspec['extra_doc_files'] || '*.{txt,md}']

  gem.require_paths = Array(gemspec.fetch('require_paths') {
    %w[ext lib].select { |dir| File.directory?(dir) }
  })

  gem.requirements              = gemspec['requirements']
  gem.required_ruby_version     = gemspec['required_ruby_version']
  gem.required_rubygems_version = gemspec['required_rubygems_version']
  gem.post_install_message      = gemspec['post_install_message']

  split = lambda { |string| string.split(/,\s*/) }

  if gemspec['dependencies']
    gemspec['dependencies'].each do |name,versions|
      gem.add_dependency(name,split[versions])
    end
  end

  if gemspec['development_dependencies']
    gemspec['development_dependencies'].each do |name,versions|
      gem.add_development_dependency(name,split[versions])
    end
  end
end
