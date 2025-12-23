require 'test_helper'

class ExecContextTest < MiniTest::Spec
  for_formats(
    :hash => [Representable::Hash, {Song => "Rebel Fate"}, {Song=>"Timing"}],
    # :xml  => [Representable::XML, "<open_struct>\n  <song>\n    <name>Alive</name>\n  </song>\n</open_struct>", "<open_struct><song><name>You've Taken Everything</name></song>/open_struct>"],
    # :yaml => [Representable::YAML, "---\nsong:\n  name: Alive\n", "---\nsong:\n  name: You've Taken Everything\n"],
  ) do |format, mod, input, output|

    let(:song) { representer.prepare(Song.new("Timing")) }
    let(:format) { format }


    describe "exec_context: nil" do
      representer!(:module => mod) do
        property :name, :as => lambda { |*| self.class }
      end

      it { render(song).must_equal_document output }
      it { _(parse(song, input).name).must_equal "Rebel Fate" }
    end


    describe "exec_context: :decorator" do
      representer!(:module => mod) do
        property :name, :as => lambda { |*| self.class }, :exec_context => :decorator
      end

      it { render(song).must_equal_document output }
      it { _(parse(song, input).name).must_equal "Rebel Fate" }
    end


    describe "exec_context: :binding" do
      representer!(:module => mod) do
        property :name,
          :as           => lambda { |*| self.class }, # to actually test
          :exec_context => :binding,
          :setter        => lambda { |options| options[:represented].name = options[:fragment] # to make parsing work.
        }
      end

      it { render(song).must_equal_document({Representable::Hash::Binding => "name"}) }
      it { _(parse(song, {Representable::Hash::Binding => "Rebel Fate"}).name).must_equal "Rebel Fate" }
    end


    describe "Decorator" do
      # DISCUSS: do we need this test?
      describe "exec_context: nil" do
        representer!(:module => mod, :decorator => true) do
          property :name, :as => lambda { |*| self.class }
        end

        it { render(song).must_equal_document output }
        it { _(parse(song, input).name).must_equal "Rebel Fate" }
      end


      describe "exec_context: :decorator" do # this tests if lambdas are run in the right context, if methods are called in the right context and if we can access the represented object.
        representer!(:module => mod, :decorator => true) do
          property :name, :as => lambda { |*| self.class.superclass }, :exec_context => :decorator

          define_method :name do # def in Decorator class.
            "Timebomb"
          end

          define_method :"name=" do |v| # def in Decorator class.
            represented.name = v
          end
        end

        it { render(song).must_equal_document({Representable::Decorator=>"Timebomb"}) }
        it { _(parse(song, {Representable::Decorator=>"Listless"}).name).must_equal "Listless" }
      end


      # DISCUSS: do we need this test?
      describe "exec_context: :binding" do
        representer!(:module => mod, :decorator => true) do
          property :name,
            :as           => lambda { |*| self.class }, # to actually test
            :exec_context => :binding,
            :setter        => lambda { |options| options[:represented].name = options[:fragment ] # to make parsing work.
          }
        end

        it { render(song).must_equal_document({Representable::Hash::Binding => "name"}) }
        it("xxx") { _(parse(song, {Representable::Hash::Binding => "Rebel Fate"}).name).must_equal "Rebel Fate" }
      end
    end
  end
end