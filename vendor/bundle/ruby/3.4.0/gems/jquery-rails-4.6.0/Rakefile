require 'bundler'
require 'rake/testtask'
Bundler::GemHelper.install_tasks

task default: :test

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.warning = true
  t.verbose = true
end

# Check if versions are correct between VERSION constants and .js files
#
task :release => [:guard_version]

task :guard_version do
  def check_version(file, pattern, constant)
    body = File.read("vendor/assets/javascripts/#{file}")
    match = body.match(pattern) or abort "Version check failed: no pattern matched in #{file}"
    file_version = match[1]
    constant_version = Jquery::Rails.const_get(constant)

    unless constant_version == file_version
      abort "Jquery::Rails::#{constant} was #{constant_version} but it should be #{file_version}"
    end
  end

  check_version('jquery.js', /jQuery JavaScript Library v([\S]+)/, 'JQUERY_VERSION')
  check_version('jquery2.js', /jQuery JavaScript Library v([\S]+)/, 'JQUERY_2_VERSION')
  check_version('jquery3.js', /jQuery JavaScript Library v([\S]+)/, 'JQUERY_3_VERSION')
end

desc "Update jQuery versions"
task :update_jquery do
  def download_jquery(filename, version)
    suffix = "-#{version}"

    puts "Downloading #{filename}.js"
    puts `curl -o vendor/assets/javascripts/#{filename}.js https://code.jquery.com/jquery#{suffix}.js`
    puts "Downloading #{filename}.min.js"
    puts `curl -o vendor/assets/javascripts/#{filename}.min.js https://code.jquery.com/jquery#{suffix}.min.js`
    puts "Downloading #{filename}.min.map"
    puts `curl -o vendor/assets/javascripts/#{filename}.min.map https://code.jquery.com/jquery#{suffix}.min.map`
  end

  download_jquery('jquery', Jquery::Rails::JQUERY_VERSION)
  download_jquery('jquery2', Jquery::Rails::JQUERY_2_VERSION)
  download_jquery('jquery3', Jquery::Rails::JQUERY_3_VERSION)
  puts "\e[32mDone!\e[0m"
end

desc "Update jQuery UJS version"
task :update_jquery_ujs do
  puts "Downloading jquery_ujs.js"
  puts `curl -o vendor/assets/javascripts/jquery_ujs.js https://raw.githubusercontent.com/rails/jquery-ujs/v#{Jquery::Rails::JQUERY_UJS_VERSION}/src/rails.js`
  puts "\e[32mDone!\e[0m"
end
