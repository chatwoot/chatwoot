require "administrate/field/active_storage"

describe Administrate::Field::ActiveStorage do
  describe "#to_partial_path" do
    it "returns a partial based on the page being rendered" do
      page = :show
      field = Administrate::Field::ActiveStorage.new(:image, "/a.jpg", page)

      path = field.to_partial_path

      expect(path).to eq("/fields/active_storage/#{page}")
    end
  end
end
