Gem::Specification.new do |s|
  s.name        = "letter_opener"
  s.version     = "1.10.0"
  s.author      = "Ryan Bates"
  s.email       = "ryan@railscasts.com"
  s.homepage    = "https://github.com/ryanb/letter_opener"
  s.summary     = "Preview mail in browser instead of sending."
  s.description = "When mail is sent from your application, Letter Opener will open a preview in the browser instead of sending."
  s.license     = "MIT"

  s.files        = Dir["{lib,spec}/**/*", "[A-Z]*"] - ["Gemfile.lock"]
  s.require_path = "lib"

  s.add_dependency 'launchy', '>= 2.2', '< 4'

  s.add_development_dependency 'rspec', '~> 3.10.0'
  s.add_development_dependency 'mail', '~> 2.6.0'

  s.required_rubygems_version = ">= 1.3.4"

  if s.respond_to?(:metadata)
    s.metadata = {
      'bug_tracker_uri' => 'https://github.com/ryanb/letter_opener/issues',
      'changelog_uri' => 'https://github.com/ryanb/letter_opener/blob/master/CHANGELOG.md',
      'documentation_uri' => 'http://www.rubydoc.info/gems/letter_opener/',
      'homepage_uri' => 'https://github.com/ryanb/letter_opener',
      'source_code_uri' => 'https://github.com/ryanb/letter_opener/',
    }
  end
end
