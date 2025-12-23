# require 'test_helper'
# require 'uber/inheritable_included'

# module InheritIncludedTo
#   def self.call(includer, proc)
#     proc.call(includer) # das will ich eigentlich machen

#     includer.class_eval do
#       @block = proc

#       def self.included(base) #
#         InheritIncludedTo.call(base, instance_variable_get(:@block))
#       end
#     end
#   end
# end

# class InheritanceTest < MiniTest::Spec
#   module Feature
#     #extend Uber::InheritedIncluded

#     CODE_BLOCK = lambda { |base| base.class_eval { extend ClassMethods } } # i want that to be executed at every include


#     def self.included(includer) #
#       # CODE_BLOCK.call(base)
#       InheritIncludedTo.call(includer, CODE_BLOCK)
#     end

#     module ClassMethods
#       def feature; end
#     end
#   end

#   module Extension
#     include Feature

#     # TODO: test overriding ::included
#   end

#   module Client
#     include Extension
#   end

#   module ExtendedClient
#     include Client
#   end

#   it { Extension.must_respond_to :feature }
#   it { Client.must_respond_to :feature }
#   it { ExtendedClient.must_respond_to :feature }
# end
