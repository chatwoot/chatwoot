# # #
# Get gemspec info

gemspec_file = Dir['*.gemspec'].first
gemspec = eval File.read(gemspec_file), binding, gemspec_file
info = "#{gemspec.name} | #{gemspec.version} | " \
       "#{gemspec.runtime_dependencies.size} dependencies | " \
       "#{gemspec.files.size} files"

# # #
# Gem build and install task

desc info
task :gem do
  puts info + "\n\n"
  print "  "; sh "gem build #{gemspec_file}"
  FileUtils.mkdir_p 'pkg'
  FileUtils.mv "#{gemspec.name}-#{gemspec.version}.gem", 'pkg'
  puts; sh %{gem install --no-document pkg/#{gemspec.name}-#{gemspec.version}.gem}
end

# # #
# Start an IRB session with the gem loaded

desc "#{gemspec.name} | IRB"
task :irb do
  sh "irb -I ./lib -r #{gemspec.name.gsub '-','/'}"
end

# # #
# Run specs

desc "#{gemspec.name} | Spec"
task :spec do
  ruby File.join("spec", "*_spec.rb")
end
task default: :spec


# # #
# Generate regex

desc "#{gemspec.name} | Generates all regex constants and saves them to lib/unicode/emoji/{generated,generated_native} directories"
task :generate_constants do
  load "data/generate_constants.rb", true
end
