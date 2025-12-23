# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elastic_apm/version'

Gem::Specification.new do |spec|
  spec.name    = 'elastic-apm'
  spec.version = ElasticAPM::VERSION
  spec.authors = ['Mikkel Malmberg', 'Emily Stolfo']
  spec.email   = ['info@elastic.co']

  spec.summary  = 'The official Elastic APM agent for Ruby'
  spec.homepage = 'https://github.com/elastic/apm-agent-ruby'
  spec.metadata = { 'source_code_uri' => 'https://github.com/elastic/apm-agent-ruby' }
  spec.license  = 'Apache-2.0'
  spec.required_ruby_version = ">= 2.3.0"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.add_dependency('concurrent-ruby', '~> 1.0')
  spec.add_dependency('http', '>= 3.0')
  spec.add_runtime_dependency('ruby2_keywords')

  spec.require_paths = ['lib']
end
