require "test_helper"

class HeritageTest < Minitest::Spec
  module Hello
    def hello
      "Hello!"
    end
  end

  module Ciao
    def ciao
      "Ciao!"
    end
  end

  class A < Representable::Decorator
    include Representable::Hash

    feature Hello

    property :id do
    end
  end

  class B < A
    feature Ciao # does NOT extend id, of course.

    property :id, inherit: true do

    end
  end

  class C < A
    property :id do end # overwrite old :id.
  end

  it "B must inherit Hello! feature from A" do
    _(B.representable_attrs.get(:id)[:extend].(nil).new(nil).hello).must_equal "Hello!"
  end

  it "B must have Ciao from module (feauture) Ciao" do
    _(B.representable_attrs.get(:id)[:extend].(nil).new(nil).ciao).must_equal "Ciao!"
  end

  it "C must inherit Hello! feature from A" do
    _(C.representable_attrs.get(:id)[:extend].(nil).new(nil).hello).must_equal "Hello!"
  end

  module M
    include Representable
    feature Hello
  end

  module N
    include Representable
    include M
    feature Ciao
  end

  let(:obj_extending_N) { Object.new.extend(N) }

  it "obj should inherit from N, and N from M" do
    _(obj_extending_N.hello).must_equal "Hello!"
  end
end
