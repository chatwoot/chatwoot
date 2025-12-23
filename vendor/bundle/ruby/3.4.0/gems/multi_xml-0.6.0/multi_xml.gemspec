# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'multi_xml/version'

Gem::Specification.new do |spec|
  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.author = 'Erik Michaels-Ober'
  spec.description = 'Provides swappable XML backends utilizing LibXML, Nokogiri, Ox, or REXML.'
  spec.email = 'sferik@gmail.com'
  spec.files = %w(.yardopts CHANGELOG.md CONTRIBUTING.md LICENSE.md README.md multi_xml.gemspec) + Dir['lib/**/*.rb']
  spec.homepage = 'https://github.com/sferik/multi_xml'
  spec.licenses = ['MIT']
  spec.name = 'multi_xml'
  spec.require_paths = ['lib']
  spec.required_rubygems_version = '>= 1.3.5'
  spec.summary = 'A generic swappable back-end for XML parsing'
  spec.version = MultiXml::Version
end
