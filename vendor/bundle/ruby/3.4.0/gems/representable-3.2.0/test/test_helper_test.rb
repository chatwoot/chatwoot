require 'test_helper'

class TestHelperTest < MiniTest::Spec
  describe "#assert_json" do
    it "tests for equality" do
      assert_json "{\"songs\":{\"one\":\"65\",\"two\":\"Emo Boy\"}}", "{\"songs\":{\"one\":\"65\",\"two\":\"Emo Boy\"}}"
    end
    
    it "allows different key orders" do
      assert_json "{\"songs\":{\"one\":\"65\",\"two\":\"Emo Boy\"}}", "{\"songs\":{\"two\":\"Emo Boy\",\"one\":\"65\"}}"
    end
    
    it "complains when expected hash is subset" do
      assert_raises MiniTest::Assertion do
        assert_json "{\"songs\":{\"one\":\"65\"}}", "{\"songs\":{\"two\":\"Emo Boy\",\"one\":\"65\"}}"
      end
    end
    
    it "complains when source hash is subset" do
      assert_raises MiniTest::Assertion do
        assert_json "{\"songs\":{\"two\":\"Emo Boy\",\"one\":\"65\"}}", "{\"songs\":{\"one\":\"65\"}}"
      end
    end
  end
end
