# frozen_string_literal: true

require "spec_helper"

describe PgSearch::Configuration::ForeignColumn do
  describe "#alias" do
    with_model :AssociatedModel do
      table do |t|
        t.string "title"
      end
    end

    with_model :Model do
      table do |t|
        t.string "title"
        t.belongs_to :another_model, index: false
      end

      model do
        include PgSearch::Model
        belongs_to :another_model, class_name: 'AssociatedModel'

        pg_search_scope :with_another, associated_against: { another_model: :title }
      end
    end

    it "returns a consistent string" do
      association = PgSearch::Configuration::Association.new(Model,
                                                             :another_model,
                                                             :title)
      foreign_column = described_class.new("title", nil, Model, association)

      column_alias = foreign_column.alias
      expect(column_alias).to be_a String
      expect(foreign_column.alias).to eq column_alias
    end
  end
end
