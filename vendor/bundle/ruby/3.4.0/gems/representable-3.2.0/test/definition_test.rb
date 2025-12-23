require 'test_helper'

class DefinitionTest < MiniTest::Spec
  Definition = Representable::Definition

  # TODO: test that we DON'T clone options, that must happen in
  describe "#initialize" do
    it do
      # new yields the defaultized options HASH.
      definition = Definition.new(:song, :extend => Module) do |options|
        options[:awesome] = true
        options[:parse_filter] << 1

        # default variables
        _(options[:as]).must_be_nil
        _(options[:extend]).must_equal Module
      end
      _(definition.name).must_equal "song"

      #
      _(definition[:awesome]).must_equal true
      _(definition[:parse_filter]).must_equal Representable::Pipeline[1]
      _(definition[:render_filter]).must_equal Representable::Pipeline[]
    end
  end

  describe "#[]" do
    let(:definition) { Definition.new(:song) }
    # default is nil.
    it { _(definition[:bla]).must_be_nil }
  end

  # merge!
  describe "#merge!" do
    let(:definition) { Definition.new(:song, :whatever => true) }

    # merges new options.
    it { _(definition.merge!(:something => true)[:something]).must_equal true }
    # doesn't override original options.
    it { _(definition.merge!({:something => true})[:whatever]).must_equal true }
    # override original when passed in #merge!.
    it { _(definition.merge!({:whatever => false})[:whatever]).must_equal false }

    # with block
    it do
      definition = Definition.new(:song, :extend => Module).merge!({:something => true}) do |options|
        options[:awesome] = true
        options[:render_filter] << 1

        # default variables
        # options[:as].must_equal "song"
        # options[:extend].must_equal Module
      end

      _(definition[:awesome]).must_equal true
      _(definition[:something]).must_equal true
      _(definition[:render_filter]).must_equal Representable::Pipeline[1]
      _(definition[:parse_filter]).must_equal Representable::Pipeline[]
    end

    describe "with :parse_filter" do
      let(:definition) { Definition.new(:title, :parse_filter => 1) }

      # merges :parse_filter and :render_filter.
      it do
        merged = definition.merge!(:parse_filter => 2)[:parse_filter]

        _(merged).must_be_kind_of Representable::Pipeline
        _(merged.size).must_equal 2
      end

      # :parse_filter can also be array.
      it { _(definition.merge!(:parse_filter => [2, 3])[:parse_filter].size).must_equal 3 }
    end

    # does not change arguments
    it do
      Definition.new(:title).merge!(options = {:whatever => 1})
      _(options).must_equal(:whatever => 1)
    end
  end


  # delete!
  describe "#delete!" do
    let(:definition) { Definition.new(:song, serialize: "remove me!") }

    before { _(definition[:serialize].(nil)).must_equal "remove me!" }

    it { _(definition.delete!(:serialize)[:serialize]).must_be_nil }
  end

  # #inspect
  describe "#inspect" do
    it { _(Definition.new(:songs).inspect).must_equal "#<Representable::Definition ==>songs @options={:name=>\"songs\", :parse_filter=>[], :render_filter=>[]}>" }
  end


  describe "generic API" do
    before do
      @def = Representable::Definition.new(:songs)
    end

    it "responds to #representer_module" do
      assert_nil Representable::Definition.new(:song).representer_module
      assert_equal Hash, Representable::Definition.new(:song, :extend => Hash).representer_module
    end

    describe "#typed?" do
      it "is false per default" do
        refute @def.typed?
      end

      it "is true when :class is present" do
        assert Representable::Definition.new(:songs, :class => Hash).typed?
      end

      it "is true when :extend is present, only" do
        assert Representable::Definition.new(:songs, :extend => Hash).typed?
      end

      it "is true when :instance is present, only" do
        assert Representable::Definition.new(:songs, :instance => Object.new).typed?
      end
    end


    describe "#representable?" do
      it { assert Definition.new(:song, :representable => true).representable? }
      it { _(Definition.new(:song, :representable => true, :extend => Object).representable?).must_equal true }
      it { refute Definition.new(:song, :representable => false, :extend => Object).representable? }
      it { assert Definition.new(:song, :extend => Object).representable? }
      it { refute Definition.new(:song).representable? }
    end


    it "responds to #getter and returns string" do
      assert_equal "songs", @def.getter
    end

    it "responds to #name" do
      assert_equal "songs", @def.name
    end

    it "responds to #setter" do
      assert_equal :"songs=", @def.setter
    end

    describe "nested: FIXME" do
      it do
        dfn = Representable::Definition.new(:songs, nested: Module)
        assert dfn.typed?
        _(dfn[:extend].(nil)).must_equal Module
      end
    end


    describe "#clone" do
      subject { Representable::Definition.new(:title, :volume => 9, :clonable => ::Representable::Option(1)) }

      it { _(subject.clone).must_be_kind_of Representable::Definition }
      it { _(subject.clone[:clonable].(nil)).must_equal 1 }

      it "clones @options" do
        @def.merge!(:volume => 9)

        cloned = @def.clone
        cloned.merge!(:volume => 8)

        assert_equal @def[:volume], 9
        assert_equal cloned[:volume], 8
      end
    end
  end

  describe "#has_default?" do
    it "returns false if no :default set" do
      refute Representable::Definition.new(:song).has_default?
    end

    it "returns true if :default set" do
      assert Representable::Definition.new(:song, :default => nil).has_default?
    end
  end


  describe "#binding" do
    it "returns true when :binding is set" do
      assert Representable::Definition.new(:songs, :binding => Object)[:binding]
    end

    it "returns false when :binding is not set" do
      refute Representable::Definition.new(:songs)[:binding]
    end
  end

  describe "#create_binding" do
    it "executes the block (without special context)" do
      definition = Representable::Definition.new(:title, :binding => lambda { |*args| @binding = Representable::Binding.new(*args) })
      _(definition.create_binding).must_equal @binding
    end
  end

  describe ":collection => true" do
    before do
      @def = Representable::Definition.new(:songs, :collection => true, :tag => :song)
    end

    it "responds to #array?" do
      assert @def.array?
    end
  end


  describe ":default => value" do
    it "responds to #default" do
      @def = Representable::Definition.new(:song)
      assert_nil @def[:default]
    end

    it "accepts a default value" do
      @def = Representable::Definition.new(:song, :default => "Atheist Peace")
      assert_equal "Atheist Peace", @def[:default]
    end
  end

  describe ":hash => true" do
    before do
      @def = Representable::Definition.new(:songs, :hash => true)
    end

    it "responds to #hash?" do
      assert @def.hash?
      refute Representable::Definition.new(:songs).hash?
    end
  end

  describe ":binding => Object" do
    subject do
      Representable::Definition.new(:songs, :binding => Object)
    end

    it "responds to #binding" do
      assert_equal subject[:binding], Object
    end
  end

  describe "#[]=" do
    it "raises exception since it's deprecated" do
      assert_raises NoMethodError do
        Definition.new(:title)[:extend] = Module.new # use merge! after initialize.
      end
    end
  end
end
