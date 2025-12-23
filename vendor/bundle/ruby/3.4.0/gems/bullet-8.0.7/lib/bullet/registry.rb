# frozen_string_literal: true

module Bullet
  module Registry
    autoload :Base, 'bullet/registry/base'
    autoload :Object, 'bullet/registry/object'
    autoload :Association, 'bullet/registry/association'
    autoload :CallStack, 'bullet/registry/call_stack'
  end
end
