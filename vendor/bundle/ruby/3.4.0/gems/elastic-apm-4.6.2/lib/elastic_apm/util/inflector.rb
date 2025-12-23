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

# frozen_string_literal: true

module ElasticAPM
  # rubocop:disable all
  module Util
    # From https://github.com/rails/rails/blob/v5.2.0/activesupport/lib/active_support/inflector/methods.rb#L254-L332
    module Inflector
      extend self

      #
      # Tries to find a constant with the name specified in the argument string.
      #
      #   constantize('Module')   # => Module
      #   constantize('Foo::Bar') # => Foo::Bar
      #
      # The name is assumed to be the one of a top-level constant, no matter
      # whether it starts with "::" or not. No lexical context is taken into
      # account:
      #
      #   C = 'outside'
      #   module M
      #     C = 'inside'
      #     C                # => 'inside'
      #     constantize('C') # => 'outside', same as ::C
      #   end
      #
      # NameError is raised when the name is not in CamelCase or the constant is
      # unknown.
      def constantize(camel_cased_word)
        names = camel_cased_word.split("::".freeze)

        # Trigger a built-in NameError exception including the ill-formed constant in the message.
        Object.const_get(camel_cased_word) if names.empty?

        # Remove the first blank element in case of '::ClassName' notation.
        names.shift if names.size > 1 && names.first.empty?

        names.inject(Object) do |constant, name|
          if constant == Object
            constant.const_get(name)
          else
            candidate = constant.const_get(name)
            next candidate if constant.const_defined?(name, false)
            next candidate unless Object.const_defined?(name)

            # Go down the ancestors to check if it is owned directly. The check
            # stops when we reach Object or the end of ancestors tree.
            constant = constant.ancestors.inject(constant) do |const, ancestor|
              break const    if ancestor == Object
              break ancestor if ancestor.const_defined?(name, false)
              const
            end

            # owner is in Object, so raise
            constant.const_get(name, false)
          end
        end
      end

      # Tries to find a constant with the name specified in the argument string.
      #
      #   safe_constantize('Module')   # => Module
      #   safe_constantize('Foo::Bar') # => Foo::Bar
      #
      # The name is assumed to be the one of a top-level constant, no matter
      # whether it starts with "::" or not. No lexical context is taken into
      # account:
      #
      #   C = 'outside'
      #   module M
      #     C = 'inside'
      #     C                     # => 'inside'
      #     safe_constantize('C') # => 'outside', same as ::C
      #   end
      #
      # +nil+ is returned when the name is not in CamelCase or the constant (or
      # part of it) is unknown.
      #
      #   safe_constantize('blargle')                  # => nil
      #   safe_constantize('UnknownModule')            # => nil
      #   safe_constantize('UnknownModule::Foo::Bar')  # => nil
      def safe_constantize(camel_cased_word)
        constantize(camel_cased_word)
      rescue NameError => e
        raise if e.name && !(camel_cased_word.to_s.split("::").include?(e.name.to_s) ||
                             e.name.to_s == camel_cased_word.to_s)
      rescue ArgumentError => e
        raise unless /not missing constant #{const_regexp(camel_cased_word)}!$/.match(e.message)
      end
    end
  end
  # rubocop:enable all
end
