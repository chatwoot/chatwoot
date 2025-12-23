# frozen_string_literal: true

require "spec_helper"

describe "pagination" do
  describe "using LIMIT and OFFSET" do
    with_model :PaginatedModel do
      table do |t|
        t.string :name
      end

      model do
        include PgSearch::Model
        pg_search_scope :search_name, against: :name

        def self.page(page_number)
          offset = (page_number - 1) * 2
          limit(2).offset(offset)
        end
      end
    end

    it "is chainable before a search scope" do
      better = PaginatedModel.create!(name: "foo foo bar")
      best = PaginatedModel.create!(name: "foo foo foo")
      good = PaginatedModel.create!(name: "foo bar bar")

      expect(PaginatedModel.page(1).search_name("foo")).to eq([best, better])
      expect(PaginatedModel.page(2).search_name("foo")).to eq([good])
    end

    it "is chainable after a search scope" do
      better = PaginatedModel.create!(name: "foo foo bar")
      best = PaginatedModel.create!(name: "foo foo foo")
      good = PaginatedModel.create!(name: "foo bar bar")

      expect(PaginatedModel.search_name("foo").page(1)).to eq([best, better])
      expect(PaginatedModel.search_name("foo").page(2)).to eq([good])
    end
  end
end
