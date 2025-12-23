# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/NestedGroups
describe "a pg_search_scope" do
  context "when joining to another table" do
    context "without an :against" do
      with_model :AssociatedModel do
        table do |t|
          t.string "title"
        end
      end

      with_model :ModelWithoutAgainst do
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

      it "returns rows that match the query in the columns of the associated model only" do
        associated = AssociatedModel.create!(title: 'abcdef')
        included = [
          ModelWithoutAgainst.create!(title: 'abcdef', another_model: associated),
          ModelWithoutAgainst.create!(title: 'ghijkl', another_model: associated)
        ]
        excluded = [
          ModelWithoutAgainst.create!(title: 'abcdef')
        ]

        results = ModelWithoutAgainst.with_another('abcdef')
        expect(results.map(&:title)).to match_array(included.map(&:title))
        expect(results).not_to include(excluded)
      end
    end

    context "via a belongs_to association" do
      with_model :AssociatedModel do
        table do |t|
          t.string 'title'
        end
      end

      with_model :ModelWithBelongsTo do
        table do |t|
          t.string 'title'
          t.belongs_to 'another_model', index: false
        end

        model do
          include PgSearch::Model
          belongs_to :another_model, class_name: 'AssociatedModel'

          pg_search_scope :with_associated, against: :title, associated_against: { another_model: :title }
        end
      end

      it "returns rows that match the query in either its own columns or the columns of the associated model" do
        associated = AssociatedModel.create!(title: 'abcdef')
        included = [
          ModelWithBelongsTo.create!(title: 'ghijkl', another_model: associated),
          ModelWithBelongsTo.create!(title: 'abcdef')
        ]
        excluded = ModelWithBelongsTo.create!(title: 'mnopqr',
                                              another_model: AssociatedModel.create!(title: 'stuvwx'))

        results = ModelWithBelongsTo.with_associated('abcdef')
        expect(results.map(&:title)).to match_array(included.map(&:title))
        expect(results).not_to include(excluded)
      end
    end

    context "via a has_many association" do
      with_model :AssociatedModelWithHasMany do
        table do |t|
          t.string 'title'
          t.belongs_to 'ModelWithHasMany', index: false
        end
      end

      with_model :ModelWithHasMany do
        table do |t|
          t.string 'title'
        end

        model do
          include PgSearch::Model
          has_many :other_models, class_name: 'AssociatedModelWithHasMany', foreign_key: 'ModelWithHasMany_id'

          pg_search_scope :with_associated, against: [:title], associated_against: { other_models: :title }
        end
      end

      it "returns rows that match the query in either its own columns or the columns of the associated model" do
        included = [
          ModelWithHasMany.create!(title: 'abcdef', other_models: [
            AssociatedModelWithHasMany.create!(title: 'foo'),
            AssociatedModelWithHasMany.create!(title: 'bar')
          ]),
          ModelWithHasMany.create!(title: 'ghijkl', other_models: [
            AssociatedModelWithHasMany.create!(title: 'foo bar'),
            AssociatedModelWithHasMany.create!(title: 'mnopqr')
          ]),
          ModelWithHasMany.create!(title: 'foo bar')
        ]
        excluded = ModelWithHasMany.create!(title: 'stuvwx', other_models: [
          AssociatedModelWithHasMany.create!(title: 'abcdef')
        ])

        results = ModelWithHasMany.with_associated('foo bar')
        expect(results.map(&:title)).to match_array(included.map(&:title))
        expect(results).not_to include(excluded)
      end

      it "uses an unscoped relation of the associated model" do
        excluded = ModelWithHasMany.create!(title: 'abcdef', other_models: [
          AssociatedModelWithHasMany.create!(title: 'abcdef')
        ])

        included = [
          ModelWithHasMany.create!(title: 'abcdef', other_models: [
            AssociatedModelWithHasMany.create!(title: 'foo'),
            AssociatedModelWithHasMany.create!(title: 'bar')
          ])
        ]

        results = ModelWithHasMany
                  .limit(1)
                  .order(Arel.sql("#{ModelWithHasMany.quoted_table_name}.id ASC"))
                  .with_associated('foo bar')

        expect(results.map(&:title)).to match_array(included.map(&:title))
        expect(results).not_to include(excluded)
      end
    end

    context "when across multiple associations" do
      context "when on different tables" do
        with_model :FirstAssociatedModel do
          table do |t|
            t.string 'title'
            t.belongs_to 'ModelWithManyAssociations', index: false
          end
        end

        with_model :SecondAssociatedModel do
          table do |t|
            t.string 'title'
          end
        end

        with_model :ModelWithManyAssociations do
          table do |t|
            t.string 'title'
            t.belongs_to 'model_of_second_type', index: false
          end

          model do
            include PgSearch::Model

            has_many :models_of_first_type,
                     class_name: 'FirstAssociatedModel',
                     foreign_key: 'ModelWithManyAssociations_id'

            belongs_to :model_of_second_type,
                       class_name: 'SecondAssociatedModel'

            pg_search_scope :with_associated,
                            against: :title,
                            associated_against: { models_of_first_type: :title, model_of_second_type: :title }
          end
        end

        it "returns rows that match the query in either its own columns or the columns of the associated model" do
          matching_second = SecondAssociatedModel.create!(title: "foo bar")
          unmatching_second = SecondAssociatedModel.create!(title: "uiop")

          included = [
            ModelWithManyAssociations.create!(title: 'abcdef', models_of_first_type: [
              FirstAssociatedModel.create!(title: 'foo'),
              FirstAssociatedModel.create!(title: 'bar')
            ]),
            ModelWithManyAssociations.create!(title: 'ghijkl', models_of_first_type: [
              FirstAssociatedModel.create!(title: 'foo bar'),
              FirstAssociatedModel.create!(title: 'mnopqr')
            ]),
            ModelWithManyAssociations.create!(title: 'foo bar'),
            ModelWithManyAssociations.create!(title: 'qwerty', model_of_second_type: matching_second)
          ]
          excluded = [
            ModelWithManyAssociations.create!(title: 'stuvwx', models_of_first_type: [
              FirstAssociatedModel.create!(title: 'abcdef')
            ]),
            ModelWithManyAssociations.create!(title: 'qwerty', model_of_second_type: unmatching_second)
          ]

          results = ModelWithManyAssociations.with_associated('foo bar')
          expect(results.map(&:title)).to match_array(included.map(&:title))
          excluded.each { |object| expect(results).not_to include(object) }
        end
      end

      context "when on the same table" do
        with_model :DoublyAssociatedModel do
          table do |t|
            t.string 'title'
            t.belongs_to 'ModelWithDoubleAssociation', index: false
            t.belongs_to 'ModelWithDoubleAssociation_again', index: false
          end
        end

        with_model :ModelWithDoubleAssociation do
          table do |t|
            t.string 'title'
          end

          model do
            include PgSearch::Model

            has_many :things,
                     class_name: 'DoublyAssociatedModel',
                     foreign_key: 'ModelWithDoubleAssociation_id'

            has_many :thingamabobs,
                     class_name: 'DoublyAssociatedModel',
                     foreign_key: 'ModelWithDoubleAssociation_again_id'

            pg_search_scope :with_associated, against: :title,
                                              associated_against: { things: :title, thingamabobs: :title }
          end
        end

        it "returns rows that match the query in either its own columns or the columns of the associated model" do
          included = [
            ModelWithDoubleAssociation.create!(title: 'abcdef', things: [
              DoublyAssociatedModel.create!(title: 'foo'),
              DoublyAssociatedModel.create!(title: 'bar')
            ]),
            ModelWithDoubleAssociation.create!(title: 'ghijkl', things: [
              DoublyAssociatedModel.create!(title: 'foo bar'),
              DoublyAssociatedModel.create!(title: 'mnopqr')
            ]),
            ModelWithDoubleAssociation.create!(title: 'foo bar'),
            ModelWithDoubleAssociation.create!(title: 'qwerty', thingamabobs: [
              DoublyAssociatedModel.create!(title: "foo bar")
            ])
          ]
          excluded = [
            ModelWithDoubleAssociation.create!(title: 'stuvwx', things: [
              DoublyAssociatedModel.create!(title: 'abcdef')
            ]),
            ModelWithDoubleAssociation.create!(title: 'qwerty', thingamabobs: [
              DoublyAssociatedModel.create!(title: "uiop")
            ])
          ]

          results = ModelWithDoubleAssociation.with_associated('foo bar')
          expect(results.map(&:title)).to match_array(included.map(&:title))
          excluded.each { |object| expect(results).not_to include(object) }
        end
      end
    end

    context "when against multiple attributes on one association" do
      with_model :AssociatedModel do
        table do |t|
          t.string 'title'
          t.text 'author'
        end
      end

      with_model :ModelWithAssociation do
        table do |t|
          t.belongs_to 'another_model', index: false
        end

        model do
          include PgSearch::Model
          belongs_to :another_model, class_name: 'AssociatedModel'

          pg_search_scope :with_associated, associated_against: { another_model: %i[title author] }
        end
      end

      it "joins only once" do
        included = [
          ModelWithAssociation.create!(
            another_model: AssociatedModel.create!(
              title: "foo",
              author: "bar"
            )
          ),
          ModelWithAssociation.create!(
            another_model: AssociatedModel.create!(
              title: "foo bar",
              author: "baz"
            )
          )
        ]
        excluded = [
          ModelWithAssociation.create!(
            another_model: AssociatedModel.create!(
              title: "foo",
              author: "baz"
            )
          )
        ]

        results = ModelWithAssociation.with_associated('foo bar')

        expect(results.to_sql.scan("INNER JOIN #{AssociatedModel.quoted_table_name}").length).to eq(1)
        included.each { |object| expect(results).to include(object) }
        excluded.each { |object| expect(results).not_to include(object) }
      end
    end

    context "when against non-text columns" do
      with_model :AssociatedModel do
        table do |t|
          t.integer 'number'
        end
      end

      with_model :Model do
        table do |t|
          t.integer 'number'
          t.belongs_to 'another_model', index: false
        end

        model do
          include PgSearch::Model
          belongs_to :another_model, class_name: 'AssociatedModel'

          pg_search_scope :with_associated, associated_against: { another_model: :number }
        end
      end

      it "casts the columns to text" do
        associated = AssociatedModel.create!(number: 123)
        included = [
          Model.create!(number: 123, another_model: associated),
          Model.create!(number: 456, another_model: associated)
        ]
        excluded = [
          Model.create!(number: 123)
        ]

        results = Model.with_associated('123')
        expect(results.map(&:number)).to match_array(included.map(&:number))
        expect(results).not_to include(excluded)
      end
    end

    context "when including the associated model" do
      with_model :Parent do
        table do |t|
          t.text :name
        end

        model do
          has_many :children
          include PgSearch::Model
          pg_search_scope :search_name, against: :name
        end
      end

      with_model :Child do
        table do |t|
          t.belongs_to :parent
        end

        model do
          belongs_to :parent
        end
      end

      # https://github.com/Casecommons/pg_search/issues/14
      it "supports queries with periods" do
        included = Parent.create!(name: 'bar.foo')
        excluded = Parent.create!(name: 'foo.bar')

        results = Parent.search_name('bar.foo').includes(:children)
        results.to_a

        expect(results).to include(included)
        expect(results).not_to include(excluded)
      end
    end
  end

  context "when merging a pg_search_scope into another model's scope" do
    with_model :ModelWithAssociation do
      model do
        has_many :associated_models
      end
    end

    with_model :AssociatedModel do
      table do |t|
        t.string :content
        t.belongs_to :model_with_association, index: false
      end

      model do
        include PgSearch::Model
        belongs_to :model_with_association

        pg_search_scope :search_content, against: :content
      end
    end

    it "finds records of the other model" do
      included_associated_1 = AssociatedModel.create(content: "foo bar")
      included_associated_2 = AssociatedModel.create(content: "foo baz")
      excluded_associated_1 = AssociatedModel.create(content: "baz quux")
      excluded_associated_2 = AssociatedModel.create(content: "baz bar")

      included = [
        ModelWithAssociation.create(associated_models: [included_associated_1]),
        ModelWithAssociation.create(associated_models: [included_associated_2, excluded_associated_1])
      ]

      excluded = [
        ModelWithAssociation.create(associated_models: [excluded_associated_2]),
        ModelWithAssociation.create(associated_models: [])
      ]

      relation = AssociatedModel.search_content("foo")

      results = ModelWithAssociation.joins(:associated_models).merge(relation)

      expect(results).to include(*included)
      expect(results).not_to include(*excluded)
    end
  end

  context "when chained onto a has_many association" do
    with_model :Company do
      model do
        has_many :positions
      end
    end

    with_model :Position do
      table do |t|
        t.string :title
        t.belongs_to :company
      end

      model do
        include PgSearch::Model
        pg_search_scope :search, against: :title, using: %i[tsearch trigram]
      end
    end

    # https://github.com/Casecommons/pg_search/issues/106
    it "handles numbers in a trigram query properly" do
      company = Company.create!
      another_company = Company.create!

      included = [
        Position.create!(company_id: company.id, title: "teller 1"),
        Position.create!(company_id: company.id, title: "teller 2") # close enough
      ]

      excluded = [
        Position.create!(company_id: nil, title: "teller 1"),
        Position.create!(company_id: another_company.id, title: "teller 1"),
        Position.create!(company_id: company.id, title: "penn 1")
      ]

      results = company.positions.search('teller 1')

      expect(results).to include(*included)
      expect(results).not_to include(*excluded)
    end
  end
end
# rubocop:enable RSpec/NestedGroups
