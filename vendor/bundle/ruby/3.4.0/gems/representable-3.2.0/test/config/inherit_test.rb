require 'test_helper'

# tests defining representers in modules, decorators and classes and the inheritance when combined.

class ConfigInheritTest < MiniTest::Spec
  def assert_cloned(child, parent, property)
    child_def  = child.representable_attrs.get(property)
    parent_def = parent.representable_attrs.get(property)

    child_def.merge!(:alias => property)

    _(child_def[:alias]).wont_equal parent_def[:alias]
    _(child_def.object_id).wont_equal parent_def.object_id
  end
  # class Object

  # end
  module GenreModule
    include Representable::Hash
    property :genre
  end


  # in Decorator ------------------------------------------------
  class Decorator < Representable::Decorator
    include Representable::Hash
    property :title
    property :artist do
      property :id
    end
  end

  it { _(Decorator.definitions.keys).must_equal ["title", "artist"] }

  # in inheriting Decorator

  class InheritingDecorator < Decorator
    property :location
  end

  it { _(InheritingDecorator.definitions.keys).must_equal ["title", "artist", "location"] }
  it { assert_cloned(InheritingDecorator, Decorator, "title") }
  it do
    _(InheritingDecorator.representable_attrs.get(:artist).representer_module.object_id).wont_equal Decorator.representable_attrs.get(:artist).representer_module.object_id
  end

  # in inheriting and including Decorator

  class InheritingAndIncludingDecorator < Decorator
    include GenreModule
    property :location
  end

  it { _(InheritingAndIncludingDecorator.definitions.keys).must_equal ["title", "artist", "genre", "location"] }
  it { assert_cloned(InheritingAndIncludingDecorator, GenreModule, :genre) }


  # in module ---------------------------------------------------
  module Module
    include Representable
    property :title
  end

  it { _(Module.definitions.keys).must_equal ["title"] }


  # in module including module
  module SubModule
    include Representable
    include Module

    property :location
  end

  it { _(SubModule.definitions.keys).must_equal ["title", "location"] }
  it { assert_cloned(SubModule, Module, :title) }

  # including preserves order
  module IncludingModule
    include Representable
    property :genre
    include Module

    property :location
  end

  it { _(IncludingModule.definitions.keys).must_equal ["genre", "title", "location"] }


  # included in class -------------------------------------------
  class Class
    include Representable
    include IncludingModule
  end

  it { _(Class.definitions.keys).must_equal ["genre", "title", "location"] }
  it { assert_cloned(Class, IncludingModule, :title) }
  it { assert_cloned(Class, IncludingModule, :location) }
  it { assert_cloned(Class, IncludingModule, :genre) }

  # included in class with order
  class DefiningClass
    include Representable
    property :street_cred
    include IncludingModule
  end

  it { _(DefiningClass.definitions.keys).must_equal ["street_cred", "genre", "title", "location"] }

  # in class
  class RepresenterClass
    include Representable
    property :title
  end

  it { _(RepresenterClass.definitions.keys).must_equal ["title"] }


  # in inheriting class
  class InheritingClass < RepresenterClass
    include Representable
    property :location
  end

  it { _(InheritingClass.definitions.keys).must_equal ["title", "location"] }
  it { assert_cloned(InheritingClass, RepresenterClass, :title) }

  # in inheriting class and including
  class InheritingAndIncludingClass < RepresenterClass
    property :location
    include GenreModule
  end

  it { _(InheritingAndIncludingClass.definitions.keys).must_equal ["title", "location", "genre"] }
end