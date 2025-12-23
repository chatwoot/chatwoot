# -*- ruby -*-

require 'rubygems'
begin
  require 'hoe'
rescue LoadError
  Gem.install 'hoe'
  retry
end

Hoe.plugins.delete :rubyforge
Hoe.plugin :minitest
Hoe.plugin :gemspec # `gem install hoe-gemspec`
Hoe.plugin :git     # `gem install hoe-git`

Hoe.spec 'hana' do
  developer('Aaron Patterson', 'aaron@tenderlovemaking.com')
  license 'MIT'
  self.readme_file   = 'README.md'
  self.extra_rdoc_files  = FileList['*.rdoc']
  extra_dev_deps << ["minitest", "~> 5.0"]
end

# vim: syntax=ruby
