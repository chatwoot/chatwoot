require "spec_helper"

describe Audited do
  describe "#store" do
    describe "maintains state of store" do
      let(:current_user) { Audited::RequestStore.audited_store }
      before { Audited.store[:current_user] = current_user }

      it "checks store is not nil" do
        expect(Audited.store[:current_user]).to eq(current_user)
      end

      it "when executed with Fibers" do
        Fiber.new { expect(Audited.store[:current_user]).to eq(current_user) }.resume
      end
    end
  end
end
