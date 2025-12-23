require 'test_helper'
require 'uber/options'

class UberOptionsTest < MiniTest::Spec
  Options = Uber::Options

  let (:dynamic) { Options.new(:volume =>1, :style => "Punkrock", :track => Proc.new { |i| i.to_s }) }

  describe "#evaluate" do
    it { dynamic.evaluate(Object.new, 999).must_equal({:volume =>1, :style => "Punkrock", :track => "999"}) }

    describe "static" do
      let (:static) { Options.new(:volume =>1, :style => "Punkrock") }

      it { static.evaluate(nil).must_equal({:volume =>1, :style => "Punkrock"}) }

      it "doesn't evaluate internally" do
        static.instance_eval do
          def evaluate_for(*)
            raise "i shouldn't be called!"
          end
        end
        static.evaluate(nil).must_equal({:volume =>1, :style => "Punkrock"})
      end
    end
  end

  describe "#eval" do
    it { dynamic.eval(:volume, 999).must_equal 1 }
    it { dynamic.eval(:style, 999).must_equal "Punkrock" }
    it { dynamic.eval(:track, Object.new, 999).must_equal "999" }
  end
end
