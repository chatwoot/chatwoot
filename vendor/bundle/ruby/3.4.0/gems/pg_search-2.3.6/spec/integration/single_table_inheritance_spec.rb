# frozen_string_literal: true

require "spec_helper"

describe "a pg_search_scope on an STI subclass" do
  context "with the standard type column" do
    with_model :SuperclassModel do
      table do |t|
        t.text 'content'
        t.string 'type'
      end

      model do
        include PgSearch::Model
        pg_search_scope :search_content, against: :content
      end
    end

    before do
      stub_const("SearchableSubclassModel", Class.new(SuperclassModel))
      stub_const("AnotherSearchableSubclassModel", Class.new(SuperclassModel))
    end

    it "returns only results for that subclass" do
      included = [
        SearchableSubclassModel.create!(content: "foo bar")
      ]
      excluded = [
        SearchableSubclassModel.create!(content: "baz"),
        SuperclassModel.create!(content: "foo bar"),
        SuperclassModel.create!(content: "baz"),
        AnotherSearchableSubclassModel.create!(content: "foo bar"),
        AnotherSearchableSubclassModel.create!(content: "baz")
      ]

      expect(SuperclassModel.count).to eq(6)
      expect(SearchableSubclassModel.count).to eq(2)

      results = SearchableSubclassModel.search_content("foo bar")

      expect(results).to include(*included)
      expect(results).not_to include(*excluded)
    end
  end

  context "with a custom type column" do
    with_model :SuperclassModel do
      table do |t|
        t.text 'content'
        t.string 'custom_type'
      end

      model do
        include PgSearch::Model
        self.inheritance_column = 'custom_type'
        pg_search_scope :search_content, against: :content
      end
    end

    before do
      stub_const("SearchableSubclassModel", Class.new(SuperclassModel))
      stub_const("AnotherSearchableSubclassModel", Class.new(SuperclassModel))
    end

    it "returns only results for that subclass" do
      included = [
        SearchableSubclassModel.create!(content: "foo bar")
      ]
      excluded = [
        SearchableSubclassModel.create!(content: "baz"),
        SuperclassModel.create!(content: "foo bar"),
        SuperclassModel.create!(content: "baz"),
        AnotherSearchableSubclassModel.create!(content: "foo bar"),
        AnotherSearchableSubclassModel.create!(content: "baz")
      ]

      expect(SuperclassModel.count).to eq(6)
      expect(SearchableSubclassModel.count).to eq(2)

      results = SearchableSubclassModel.search_content("foo bar")

      expect(results).to include(*included)
      expect(results).not_to include(*excluded)
    end
  end
end
