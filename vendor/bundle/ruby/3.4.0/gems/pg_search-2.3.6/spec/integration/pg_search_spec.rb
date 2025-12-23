# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/NestedGroups
describe "an Active Record model which includes PgSearch" do
  with_model :ModelWithPgSearch do
    table do |t|
      t.string 'title'
      t.text 'content'
      t.integer 'parent_model_id'
      t.integer 'importance'
    end

    model do
      include PgSearch::Model
      belongs_to :parent_model
    end
  end
  with_model :ParentModel do
    table do |t|
      t.boolean :active, default: true
    end

    model do
      include PgSearch::Model
      has_many :models_with_pg_search
      scope :active, -> { where(active: true) }
    end
  end

  describe ".pg_search_scope" do
    it "builds a chainable scope" do
      ModelWithPgSearch.pg_search_scope "matching_query", against: []
      scope = ModelWithPgSearch.where("1 = 1").matching_query("foo").where("1 = 1")
      expect(scope).to be_an ActiveRecord::Relation
    end

    context "when passed a lambda" do
      it "builds a dynamic scope" do
        ModelWithPgSearch.pg_search_scope :search_title_or_content,
                                          lambda { |query, pick_content|
                                            {
                                              query: query.gsub("-remove-", ""),
                                              against: pick_content ? :content : :title
                                            }
                                          }

        included = ModelWithPgSearch.create!(title: 'foo', content: 'bar')
        excluded = ModelWithPgSearch.create!(title: 'bar', content: 'foo')

        expect(ModelWithPgSearch.search_title_or_content('fo-remove-o', false)).to eq([included])
        expect(ModelWithPgSearch.search_title_or_content('b-remove-ar', true)).to eq([included])
      end
    end

    context "when an unknown option is passed in" do
      it "raises an exception when invoked" do
        ModelWithPgSearch.pg_search_scope :with_unknown_option,
                                          against: :content,
                                          foo: :bar

        expect {
          ModelWithPgSearch.with_unknown_option("foo")
        }.to raise_error(ArgumentError, /foo/)
      end

      context "with a lambda" do
        it "raises an exception when invoked" do
          ModelWithPgSearch.pg_search_scope :with_unknown_option,
                                            ->(*) { { against: :content, foo: :bar } }

          expect {
            ModelWithPgSearch.with_unknown_option("foo")
          }.to raise_error(ArgumentError, /foo/)
        end
      end
    end

    context "when an unknown :using is passed" do
      it "raises an exception when invoked" do
        ModelWithPgSearch.pg_search_scope :with_unknown_using,
                                          against: :content,
                                          using: :foo

        expect {
          ModelWithPgSearch.with_unknown_using("foo")
        }.to raise_error(ArgumentError, /foo/)
      end

      context "with a lambda" do
        it "raises an exception when invoked" do
          ModelWithPgSearch.pg_search_scope :with_unknown_using,
                                            ->(*) { { against: :content, using: :foo } }

          expect {
            ModelWithPgSearch.with_unknown_using("foo")
          }.to raise_error(ArgumentError, /foo/)
        end
      end
    end

    context "when an unknown :ignoring is passed" do
      it "raises an exception when invoked" do
        ModelWithPgSearch.pg_search_scope :with_unknown_ignoring,
                                          against: :content,
                                          ignoring: :foo

        expect {
          ModelWithPgSearch.with_unknown_ignoring("foo")
        }.to raise_error(ArgumentError, /ignoring.*foo/)
      end

      context "with a lambda" do
        it "raises an exception when invoked" do
          ModelWithPgSearch.pg_search_scope :with_unknown_ignoring,
                                            ->(*) { { against: :content, ignoring: :foo } }

          expect {
            ModelWithPgSearch.with_unknown_ignoring("foo")
          }.to raise_error(ArgumentError, /ignoring.*foo/)
        end
      end

      context "when :against is not passed in" do
        it "raises an exception when invoked" do
          ModelWithPgSearch.pg_search_scope :with_unknown_ignoring, {}

          expect {
            ModelWithPgSearch.with_unknown_ignoring("foo")
          }.to raise_error(ArgumentError, /against/)
        end

        context "with a lambda" do
          it "raises an exception when invoked" do
            ModelWithPgSearch.pg_search_scope :with_unknown_ignoring, ->(*) { {} }

            expect {
              ModelWithPgSearch.with_unknown_ignoring("foo")
            }.to raise_error(ArgumentError, /against/)
          end
        end

        context "when a tsvector column is specified" do
          it "does not raise an exception when invoked" do
            ModelWithPgSearch.pg_search_scope :with_unknown_ignoring, {
              using: {
                tsearch: {
                  tsvector_column: "tsv"
                }
              }
            }

            expect {
              ModelWithPgSearch.with_unknown_ignoring("foo")
            }.not_to raise_error
          end
        end
      end
    end
  end

  describe "a search scope" do
    context "when against a single column" do
      before do
        ModelWithPgSearch.pg_search_scope :search_content, against: :content
      end

      context "when chained after a select() scope" do
        it "honors the select" do
          included = ModelWithPgSearch.create!(content: 'foo', title: 'bar')
          excluded = ModelWithPgSearch.create!(content: 'bar', title: 'foo')

          results = ModelWithPgSearch.select('id, title').search_content('foo')

          expect(results).to include(included)
          expect(results).not_to include(excluded)

          expect(results.first.attributes.key?('content')).to eq false

          expect(results.select { |record| record.title == "bar" }).to eq [included]
          expect(results.reject { |record| record.title == "bar" }).to be_empty
        end
      end

      context "when chained before a select() scope" do
        it "honors the select" do
          included = ModelWithPgSearch.create!(content: 'foo', title: 'bar')
          excluded = ModelWithPgSearch.create!(content: 'bar', title: 'foo')

          results = ModelWithPgSearch.search_content('foo').select('id, title')

          expect(results).to include(included)
          expect(results).not_to include(excluded)

          expect(results.first.attributes.key?('content')).to eq false

          expect(results.select { |record| record.title == "bar" }).to eq [included]
          expect(results.reject { |record| record.title == "bar" }).to be_empty
        end
      end

      context "when surrouned by select() scopes" do
        it "honors the select" do
          included = ModelWithPgSearch.create!(content: 'foo', title: 'bar')
          excluded = ModelWithPgSearch.create!(content: 'bar', title: 'foo')

          results = ModelWithPgSearch.select('id').search_content('foo').select('title')

          expect(results).to include(included)
          expect(results).not_to include(excluded)

          expect(results.first.attributes.key?('content')).to eq false

          expect(results.select { |record| record.title == "bar" }).to eq [included]
          expect(results.reject { |record| record.title == "bar" }).to be_empty
        end
      end

      context "when chained to a cross-table scope" do
        with_model :House do
          table do |t|
            t.references :person
            t.string :city
          end

          model do
            include PgSearch::Model
            belongs_to :person
            pg_search_scope :search_city, against: [:city]
          end
        end

        with_model :Person do
          table do |t|
            t.string :name
          end

          model do
            include PgSearch::Model
            has_many :houses
            pg_search_scope :named, against: [:name]
            scope :with_house_in_city, lambda { |city|
              joins(:houses).where(House.table_name.to_sym => { city: city })
            }
            scope :house_search_city, lambda { |query|
              joins(:houses).merge(House.search_city(query))
            }
          end
        end

        it "works when the other scope is last" do
          house_in_duluth = House.create!(city: "Duluth")
          second_house_in_duluth = House.create!(city: "Duluth")
          house_in_sheboygan = House.create!(city: "Sheboygan")

          bob_in_duluth =
            Person.create!(name: "Bob", houses: [house_in_duluth])
          bob_in_sheboygan =
            Person.create!(name: "Bob", houses: [house_in_sheboygan])
          sally_in_duluth =
            Person.create!(name: "Sally", houses: [second_house_in_duluth])

          results = Person.named("bob").with_house_in_city("Duluth")
          expect(results).to include bob_in_duluth
          expect(results).not_to include [bob_in_sheboygan, sally_in_duluth]
        end

        it "works when the other scope is first" do
          house_in_duluth = House.create!(city: "Duluth")
          second_house_in_duluth = House.create!(city: "Duluth")
          house_in_sheboygan = House.create!(city: "Sheboygan")

          bob_in_duluth =
            Person.create!(name: "Bob", houses: [house_in_duluth])
          bob_in_sheboygan =
            Person.create!(name: "Bob", houses: [house_in_sheboygan])
          sally_in_duluth =
            Person.create!(name: "Sally", houses: [second_house_in_duluth])

          results = Person.with_house_in_city("Duluth").named("Bob")
          expect(results).to include bob_in_duluth
          expect(results).not_to include [bob_in_sheboygan, sally_in_duluth]
        end

        context "when chaining merged scopes" do
          it "does not raise an exception" do
            relation = Person.named('foo').house_search_city('bar')

            expect { relation.to_a }.not_to raise_error
          end
        end
      end

      context "when chaining scopes" do
        before do
          ModelWithPgSearch.pg_search_scope :search_title, against: :title
        end

        it "does not raise an exception" do
          relation = ModelWithPgSearch.search_content('foo').search_title('bar')

          expect { relation.to_a }.not_to raise_error
        end
      end

      it "returns an empty array when a blank query is passed in" do
        ModelWithPgSearch.create!(content: 'foo')

        results = ModelWithPgSearch.search_content('')
        expect(results).to eq([])
      end

      it "returns rows where the column contains the term in the query" do
        included = ModelWithPgSearch.create!(content: 'foo')
        excluded = ModelWithPgSearch.create!(content: 'bar')

        results = ModelWithPgSearch.search_content('foo')
        expect(results).to include(included)
        expect(results).not_to include(excluded)
      end

      it "returns the correct count" do
        ModelWithPgSearch.create!(content: 'foo')
        ModelWithPgSearch.create!(content: 'bar')

        results = ModelWithPgSearch.search_content('foo')
        expect(results.count).to eq 1
      end

      it "returns the correct count(:all)" do
        ModelWithPgSearch.create!(content: 'foo')
        ModelWithPgSearch.create!(content: 'bar')

        results = ModelWithPgSearch.search_content('foo')
        expect(results.count(:all)).to eq 1
      end

      it "supports #select" do
        record = ModelWithPgSearch.create!(content: 'foo')
        other_record = ModelWithPgSearch.create!(content: 'bar')

        records_with_only_id = ModelWithPgSearch.search_content('foo').select('id')
        expect(records_with_only_id.length).to eq 1

        returned_record = records_with_only_id.first

        expect(returned_record.attributes).to eq("id" => record.id)
      end

      it "supports #pluck" do
        record = ModelWithPgSearch.create!(content: 'foo')
        other_record = ModelWithPgSearch.create!(content: 'bar')

        ids = ModelWithPgSearch.search_content('foo').pluck('id')
        expect(ids).to eq [record.id]
      end

      it "supports adding where clauses using the pg_search.rank" do
        once = ModelWithPgSearch.create!(content: 'foo bar')
        twice = ModelWithPgSearch.create!(content: 'foo foo')

        records = ModelWithPgSearch.search_content('foo')
                                   .where("#{PgSearch::Configuration.alias(ModelWithPgSearch.table_name)}.rank > 0.07")

        expect(records).to eq [twice]
      end

      it "returns rows where the column contains all the terms in the query in any order" do
        included = [ModelWithPgSearch.create!(content: 'foo bar'),
                    ModelWithPgSearch.create!(content: 'bar foo')]
        excluded = ModelWithPgSearch.create!(content: 'foo')

        results = ModelWithPgSearch.search_content('foo bar')
        expect(results).to match_array(included)
        expect(results).not_to include(excluded)
      end

      it "returns rows that match the query but not its case" do
        included = [ModelWithPgSearch.create!(content: "foo"),
                    ModelWithPgSearch.create!(content: "FOO")]

        results = ModelWithPgSearch.search_content("Foo")
        expect(results).to match_array(included)
      end

      it "returns rows that match the query only if their accents match" do
        # \303\241 is a with acute accent
        # \303\251 is e with acute accent

        included = ModelWithPgSearch.create!(content: "abcd\303\251f")
        excluded = ModelWithPgSearch.create!(content: "\303\241bcdef")

        results = ModelWithPgSearch.search_content("abcd\303\251f")
        expect(results).to eq([included])
        expect(results).not_to include(excluded)
      end

      it "returns rows that match the query but not rows that are prefixed by the query" do
        included = ModelWithPgSearch.create!(content: 'pre')
        excluded = ModelWithPgSearch.create!(content: 'prefix')

        results = ModelWithPgSearch.search_content("pre")
        expect(results).to eq([included])
        expect(results).not_to include(excluded)
      end

      it "returns rows that match the query exactly and not those that match the query when stemmed by the default english dictionary" do
        included = ModelWithPgSearch.create!(content: "jumped")
        excluded = [ModelWithPgSearch.create!(content: "jump"),
                    ModelWithPgSearch.create!(content: "jumping")]

        results = ModelWithPgSearch.search_content("jumped")
        expect(results).to eq([included])
      end

      it "returns rows that match sorted by rank" do
        loser = ModelWithPgSearch.create!(content: 'foo')
        winner = ModelWithPgSearch.create!(content: 'foo foo')

        results = ModelWithPgSearch.search_content("foo").with_pg_search_rank
        expect(results[0].pg_search_rank).to be > results[1].pg_search_rank
        expect(results).to eq([winner, loser])
      end

      it 'preserves column selection when with_pg_search_rank is chained after a select()' do
        loser = ModelWithPgSearch.create!(title: 'foo', content: 'bar')

        results = ModelWithPgSearch.search_content('bar').select(:content).with_pg_search_rank

        expect(results.length).to be 1
        expect(results.first.as_json.keys).to contain_exactly('id', 'content', 'pg_search_rank')
      end

      it 'allows pg_search_rank along with a join' do
        parent_1 = ParentModel.create!(id: 98)
        parent_2 = ParentModel.create!(id: 99)
        loser = ModelWithPgSearch.create!(content: 'foo', parent_model: parent_2)
        winner = ModelWithPgSearch.create!(content: 'foo foo', parent_model: parent_1)

        results = ModelWithPgSearch.joins(:parent_model).merge(ParentModel.active).search_content("foo").with_pg_search_rank
        expect(results.map(&:id)).to eq [winner.id, loser.id]
        expect(results[0].pg_search_rank).to be > results[1].pg_search_rank
        expect(results).to eq([winner, loser])
      end

      it "returns results that match sorted by primary key for records that rank the same" do
        sorted_results = [ModelWithPgSearch.create!(content: 'foo'),
                          ModelWithPgSearch.create!(content: 'foo')].sort_by(&:id)

        results = ModelWithPgSearch.search_content("foo")
        expect(results).to eq(sorted_results)
      end

      it "returns results that match a query with multiple space-separated search terms" do
        included = [
          ModelWithPgSearch.create!(content: 'foo bar'),
          ModelWithPgSearch.create!(content: 'bar foo'),
          ModelWithPgSearch.create!(content: 'bar foo baz')
        ]
        excluded = [
          ModelWithPgSearch.create!(content: 'foo'),
          ModelWithPgSearch.create!(content: 'foo baz')
        ]

        results = ModelWithPgSearch.search_content('foo bar')
        expect(results).to match_array(included)
        expect(results).not_to include(excluded)
      end

      it "returns rows that match a query with characters that are invalid in a tsquery expression" do
        included = ModelWithPgSearch.create!(content: "(:Foo.) Bar?, \\")

        results = ModelWithPgSearch.search_content("foo :bar .,?() \\")
        expect(results).to eq([included])
      end

      it "accepts non-string queries and calls #to_s on them" do
        foo = ModelWithPgSearch.create!(content: "foo")
        not_a_string = instance_double("Object", to_s: "foo")
        expect(ModelWithPgSearch.search_content(not_a_string)).to eq([foo])
      end

      context "when the column is not text" do
        with_model :ModelWithTimestamps do
          table do |t|
            t.timestamps null: false
          end

          model do
            include PgSearch::Model

            # WARNING: searching timestamps is not something PostgreSQL
            # full-text search is good at. Use at your own risk.
            pg_search_scope :search_timestamps,
                            against: %i[created_at updated_at]
          end
        end

        it "casts the column to text" do
          record = ModelWithTimestamps.create!

          query = record.created_at.strftime("%Y-%m-%d")
          results = ModelWithTimestamps.search_timestamps(query)
          expect(results).to eq([record])
        end
      end
    end

    context "when against multiple columns" do
      before do
        ModelWithPgSearch.pg_search_scope :search_title_and_content, against: %i[title content]
      end

      it "returns rows whose columns contain all of the terms in the query across columns" do
        included = [
          ModelWithPgSearch.create!(title: 'foo', content: 'bar'),
          ModelWithPgSearch.create!(title: 'bar', content: 'foo')
        ]
        excluded = [
          ModelWithPgSearch.create!(title: 'foo', content: 'foo'),
          ModelWithPgSearch.create!(title: 'bar', content: 'bar')
        ]

        results = ModelWithPgSearch.search_title_and_content('foo bar')

        expect(results).to match_array(included)
        excluded.each do |result|
          expect(results).not_to include(result)
        end
      end

      it "returns rows where at one column contains all of the terms in the query and another does not" do
        in_title = ModelWithPgSearch.create!(title: 'foo', content: 'bar')
        in_content = ModelWithPgSearch.create!(title: 'bar', content: 'foo')

        results = ModelWithPgSearch.search_title_and_content('foo')
        expect(results).to match_array([in_title, in_content])
      end

      # Searching with a NULL column will prevent any matches unless we coalesce it.
      it "returns rows where at one column contains all of the terms in the query and another is NULL" do
        included = ModelWithPgSearch.create!(title: 'foo', content: nil)
        results  = ModelWithPgSearch.search_title_and_content('foo')
        expect(results).to eq([included])
      end
    end

    context "when using trigram" do
      before do
        ModelWithPgSearch.pg_search_scope :with_trigrams, against: %i[title content], using: :trigram
      end

      it "returns rows where one searchable column and the query share enough trigrams" do
        included = ModelWithPgSearch.create!(title: 'abcdefghijkl', content: nil)
        results = ModelWithPgSearch.with_trigrams('cdefhijkl')
        expect(results).to eq([included])
      end

      it "returns rows where multiple searchable columns and the query share enough trigrams" do
        included = ModelWithPgSearch.create!(title: 'abcdef', content: 'ghijkl')
        results = ModelWithPgSearch.with_trigrams('cdefhijkl')
        expect(results).to eq([included])
      end

      context "when a threshold is specified" do
        before do
          ModelWithPgSearch.pg_search_scope :with_strict_trigrams, against: %i[title content], using: { trigram: { threshold: 0.5 } }
          ModelWithPgSearch.pg_search_scope :with_permissive_trigrams, against: %i[title content], using: { trigram: { threshold: 0.1 } }
        end

        it "uses the threshold in the trigram expression" do
          low_similarity = ModelWithPgSearch.create!(title: "a")
          medium_similarity = ModelWithPgSearch.create!(title: "abc")
          high_similarity = ModelWithPgSearch.create!(title: "abcdefghijkl")

          results = ModelWithPgSearch.with_strict_trigrams("abcdefg")
          expect(results).to include(high_similarity)
          expect(results).not_to include(medium_similarity, low_similarity)

          results = ModelWithPgSearch.with_trigrams("abcdefg")
          expect(results).to include(high_similarity, medium_similarity)
          expect(results).not_to include(low_similarity)

          results = ModelWithPgSearch.with_permissive_trigrams("abcdefg")
          expect(results).to include(high_similarity, medium_similarity, low_similarity)
        end
      end
    end

    context "when using tsearch" do
      before do
        ModelWithPgSearch.pg_search_scope :search_title_with_prefixes,
                                          against: :title,
                                          using: {
                                            tsearch: { prefix: true }
                                          }
      end

      context "with prefix: true" do
        it "returns rows that match the query and that are prefixed by the query" do
          included = ModelWithPgSearch.create!(title: 'prefix')
          excluded = ModelWithPgSearch.create!(title: 'postfix')

          results = ModelWithPgSearch.search_title_with_prefixes("pre")
          expect(results).to eq([included])
          expect(results).not_to include(excluded)
        end

        it "returns rows that match the query when the query has a hyphen" do
          included = ModelWithPgSearch.create!(title: 'foo-bar')
          excluded = ModelWithPgSearch.create!(title: 'foo bar')

          results = ModelWithPgSearch.search_title_with_prefixes("foo-bar")
          expect(results).to include(included)
          expect(results).not_to include(excluded)
        end
      end

      context "with the english dictionary" do
        before do
          ModelWithPgSearch.pg_search_scope :search_content_with_english,
                                            against: :content,
                                            using: {
                                              tsearch: { dictionary: :english }
                                            }
        end

        it "returns rows that match the query when stemmed by the english dictionary" do
          included = [ModelWithPgSearch.create!(content: "jump"),
                      ModelWithPgSearch.create!(content: "jumped"),
                      ModelWithPgSearch.create!(content: "jumping")]

          results = ModelWithPgSearch.search_content_with_english("jump")
          expect(results).to match_array(included)
        end
      end

      describe "highlighting" do
        before do
          ["Strip Down", "Down", "Down and Out", "Won't Let You Down"].each do |name|
            ModelWithPgSearch.create! title: 'Just a title', content: name
          end
        end

        context "with highlight turned on" do
          before do
            ModelWithPgSearch.pg_search_scope :search_content,
                                              against: :content
          end

          it "adds a #pg_search_highlight method to each returned model record" do
            result = ModelWithPgSearch.search_content("Strip Down").with_pg_search_highlight.first

            expect(result.pg_search_highlight).to be_a(String)
          end

          it "returns excerpts of text where search match occurred" do
            result = ModelWithPgSearch.search_content("Let").with_pg_search_highlight.first

            expect(result.pg_search_highlight).to eq("Won't <b>Let</b> You Down")
          end

          it 'preserves column selection when with_pg_search_highlight is chained after a select()' do
            result = ModelWithPgSearch.search_content("Let").select(:content).with_pg_search_highlight.first

            expect(result.as_json.keys).to contain_exactly('id', 'content', 'pg_search_highlight')
          end
        end

        context "with custom highlighting options" do
          before do
            ModelWithPgSearch.create! content: "#{'text ' * 2}Let #{'text ' * 2}Let #{'text ' * 2}"

            ModelWithPgSearch.pg_search_scope :search_content,
                                              against: :content,
                                              using: {
                                                tsearch: {
                                                  highlight: {
                                                    StartSel: '<mark class="highlight">',
                                                    StopSel: '</mark>',
                                                    FragmentDelimiter: '<delim class="my_delim">',
                                                    MaxFragments: 2,
                                                    MaxWords: 2,
                                                    MinWords: 1
                                                  }
                                                }
                                              }
          end

          it "applies the options to the excerpts" do
            result = ModelWithPgSearch.search_content("Let").with_pg_search_highlight.first

            expect(result.pg_search_highlight).to eq(%(<mark class="highlight">Let</mark> text<delim class="my_delim"><mark class="highlight">Let</mark> text))
          end
        end
      end

      describe "ranking" do
        before do
          ["Strip Down", "Down", "Down and Out", "Won't Let You Down"].each do |name|
            ModelWithPgSearch.create! content: name
          end
        end

        it "adds a #pg_search_rank method to each returned model record" do
          ModelWithPgSearch.pg_search_scope :search_content, against: :content

          result = ModelWithPgSearch.search_content("Strip Down").with_pg_search_rank.first

          expect(result.pg_search_rank).to be_a(Float)
        end

        context "with a normalization specified" do
          before do
            ModelWithPgSearch.pg_search_scope :search_content_with_normalization,
                                              against: :content,
                                              using: {
                                                tsearch: { normalization: 2 }
                                              }
          end

          it "ranks the results for documents with less text higher" do
            results = ModelWithPgSearch.search_content_with_normalization("down").with_pg_search_rank

            expect(results.map(&:content)).to eq(["Down", "Strip Down", "Down and Out", "Won't Let You Down"])
            expect(results.first.pg_search_rank).to be > results.last.pg_search_rank
          end
        end

        context "with no normalization" do
          before do
            ModelWithPgSearch.pg_search_scope :search_content_without_normalization,
                                              against: :content,
                                              using: :tsearch
          end

          it "ranks the results equally" do
            results = ModelWithPgSearch.search_content_without_normalization("down").with_pg_search_rank

            expect(results.map(&:content)).to eq(["Strip Down", "Down", "Down and Out", "Won't Let You Down"])
            expect(results.first.pg_search_rank).to eq(results.last.pg_search_rank)
          end
        end
      end

      context "when against columns ranked with arrays" do
        before do
          ModelWithPgSearch.pg_search_scope :search_weighted_by_array_of_arrays,
                                            against: [[:content, 'B'], [:title, 'A']]
        end

        it "returns results sorted by weighted rank" do
          loser = ModelWithPgSearch.create!(title: 'bar', content: 'foo')
          winner = ModelWithPgSearch.create!(title: 'foo', content: 'bar')

          results = ModelWithPgSearch.search_weighted_by_array_of_arrays('foo').with_pg_search_rank
          expect(results[0].pg_search_rank).to be > results[1].pg_search_rank
          expect(results).to eq([winner, loser])
        end
      end

      context "when against columns ranked with a hash" do
        before do
          ModelWithPgSearch.pg_search_scope :search_weighted_by_hash,
                                            against: { content: 'B', title: 'A' }
        end

        it "returns results sorted by weighted rank" do
          loser = ModelWithPgSearch.create!(title: 'bar', content: 'foo')
          winner = ModelWithPgSearch.create!(title: 'foo', content: 'bar')

          results = ModelWithPgSearch.search_weighted_by_hash('foo').with_pg_search_rank
          expect(results[0].pg_search_rank).to be > results[1].pg_search_rank
          expect(results).to eq([winner, loser])
        end
      end

      context "when against columns of which only some are ranked" do
        before do
          ModelWithPgSearch.pg_search_scope :search_weighted,
                                            against: [:content, [:title, 'A']]
        end

        it "returns results sorted by weighted rank using an implied low rank for unranked columns" do
          loser = ModelWithPgSearch.create!(title: 'bar', content: 'foo')
          winner = ModelWithPgSearch.create!(title: 'foo', content: 'bar')

          results = ModelWithPgSearch.search_weighted('foo').with_pg_search_rank
          expect(results[0].pg_search_rank).to be > results[1].pg_search_rank
          expect(results).to eq([winner, loser])
        end
      end

      context "when searching any_word option" do
        before do
          ModelWithPgSearch.pg_search_scope :search_title_with_any_word,
                                            against: :title,
                                            using: {
                                              tsearch: { any_word: true }
                                            }

          ModelWithPgSearch.pg_search_scope :search_title_with_all_words,
                                            against: :title
        end

        it "returns all results containing any word in their title" do
          numbers = %w[one two three four].map { |number| ModelWithPgSearch.create!(title: number) }

          results = ModelWithPgSearch.search_title_with_any_word("one two three four")

          expect(results.map(&:title)).to eq(%w[one two three four])

          results = ModelWithPgSearch.search_title_with_all_words("one two three four")

          expect(results.map(&:title)).to eq([])
        end
      end

      context "with :negation" do
        before do
          ModelWithPgSearch.pg_search_scope :search_with_negation,
                                            against: :title,
                                            using: {
                                              tsearch: { negation: true }
                                            }
        end

        it "doesn't return results that contain terms prepended with '!'" do
          included = [
            ModelWithPgSearch.create!(title: "one fish"),
            ModelWithPgSearch.create!(title: "two fish")
          ]

          excluded = [
            ModelWithPgSearch.create!(title: "red fish"),
            ModelWithPgSearch.create!(title: "blue fish")
          ]

          results = ModelWithPgSearch.search_with_negation("fish !red !blue")

          expect(results).to include(*included)
          expect(results).not_to include(*excluded)
        end
      end

      context "without :negation" do
        before do
          ModelWithPgSearch.pg_search_scope :search_without_negation,
                                            against: :title,
                                            using: {
                                              tsearch: {}
                                            }
        end

        it "return results that contain terms prepended with '!'" do
          included = [
            ModelWithPgSearch.create!(title: "!bang")
          ]

          excluded = [
            ModelWithPgSearch.create!(title: "?question")
          ]

          results = ModelWithPgSearch.search_without_negation("!bang")

          expect(results).to include(*included)
          expect(results).not_to include(*excluded)
        end
      end
    end

    context "when using dmetaphone" do
      before do
        ModelWithPgSearch.pg_search_scope :with_dmetaphones,
                                          against: %i[title content],
                                          using: :dmetaphone
      end

      it "returns rows where one searchable column and the query share enough dmetaphones" do
        included = ModelWithPgSearch.create!(title: 'Geoff', content: nil)
        excluded = ModelWithPgSearch.create!(title: 'Bob', content: nil)
        results = ModelWithPgSearch.with_dmetaphones('Jeff')
        expect(results).to eq([included])
      end

      it "returns rows where multiple searchable columns and the query share enough dmetaphones" do
        included = ModelWithPgSearch.create!(title: 'Geoff', content: 'George')
        excluded = ModelWithPgSearch.create!(title: 'Bob', content: 'Jones')
        results = ModelWithPgSearch.with_dmetaphones('Jeff Jorge')
        expect(results).to eq([included])
      end

      it "returns rows that match dmetaphones that are English stopwords" do
        included = ModelWithPgSearch.create!(title: 'White', content: nil)
        excluded = ModelWithPgSearch.create!(title: 'Black', content: nil)
        results = ModelWithPgSearch.with_dmetaphones('Wight')
        expect(results).to eq([included])
      end

      it "can handle terms that do not have a dmetaphone equivalent" do
        term_with_blank_metaphone = "w"

        included = ModelWithPgSearch.create!(title: 'White', content: nil)
        excluded = ModelWithPgSearch.create!(title: 'Black', content: nil)

        results = ModelWithPgSearch.with_dmetaphones('Wight W')
        expect(results).to eq([included])
      end
    end

    context "when using multiple features" do
      before do
        ModelWithPgSearch.pg_search_scope :with_tsearch,
                                          against: :title,
                                          using: [
                                            [:tsearch, { dictionary: 'english' }]
                                          ]

        ModelWithPgSearch.pg_search_scope :with_trigram,
                                          against: :title,
                                          using: :trigram

        ModelWithPgSearch.pg_search_scope :with_trigram_and_ignoring_accents,
                                          against: :title,
                                          ignoring: :accents,
                                          using: :trigram

        ModelWithPgSearch.pg_search_scope :with_tsearch_and_trigram,
                                          against: :title,
                                          using: [
                                            [:tsearch, { dictionary: 'english' }],
                                            :trigram
                                          ]

        ModelWithPgSearch.pg_search_scope :complex_search,
                                          against: %i[content title],
                                          ignoring: :accents,
                                          using: {
                                            tsearch: { dictionary: 'english' },
                                            dmetaphone: {},
                                            trigram: {}
                                          }
      end

      it "returns rows that match using any of the features" do
        record = ModelWithPgSearch.create!(title: "tiling is grouty")

        # matches trigram only
        trigram_query = "ling is grouty"
        expect(ModelWithPgSearch.with_trigram(trigram_query)).to include(record)
        expect(ModelWithPgSearch.with_trigram_and_ignoring_accents(trigram_query)).to include(record)
        expect(ModelWithPgSearch.with_tsearch(trigram_query)).not_to include(record)
        expect(ModelWithPgSearch.with_tsearch_and_trigram(trigram_query)).to eq([record])
        expect(ModelWithPgSearch.complex_search(trigram_query)).to include(record)

        # matches accent
        # \303\266 is o with diaeresis
        # \303\272 is u with acute accent
        accent_query = "gr\303\266\303\272ty"
        expect(ModelWithPgSearch.with_trigram(accent_query)).not_to include(record)
        expect(ModelWithPgSearch.with_trigram_and_ignoring_accents(accent_query)).to include(record)
        expect(ModelWithPgSearch.with_tsearch(accent_query)).not_to include(record)
        expect(ModelWithPgSearch.with_tsearch_and_trigram(accent_query).count(:all)).to eq(0)
        expect(ModelWithPgSearch.complex_search(accent_query)).to include(record)

        # matches tsearch only
        tsearch_query = "tiles"
        expect(ModelWithPgSearch.with_tsearch(tsearch_query)).to include(record)
        expect(ModelWithPgSearch.with_trigram(tsearch_query)).not_to include(record)
        expect(ModelWithPgSearch.with_trigram_and_ignoring_accents(tsearch_query)).not_to include(record)
        expect(ModelWithPgSearch.with_tsearch_and_trigram(tsearch_query)).to eq([record])
        expect(ModelWithPgSearch.complex_search(tsearch_query)).to include(record)

        # matches dmetaphone only
        dmetaphone_query = "tyling"
        expect(ModelWithPgSearch.with_tsearch(dmetaphone_query)).not_to include(record)
        expect(ModelWithPgSearch.with_trigram(dmetaphone_query)).not_to include(record)
        expect(ModelWithPgSearch.with_trigram_and_ignoring_accents(dmetaphone_query)).not_to include(record)
        expect(ModelWithPgSearch.with_tsearch_and_trigram(dmetaphone_query)).not_to include(record)
        expect(ModelWithPgSearch.complex_search(dmetaphone_query)).to include(record)
      end

      context "with feature-specific configuration" do
        let(:tsearch_config) { { dictionary: 'english' } }
        let(:trigram_config) { { foo: 'bar' } }

        before do
          ModelWithPgSearch.pg_search_scope :with_tsearch_and_trigram_using_hash,
                                            against: :title,
                                            using: { tsearch: tsearch_config, trigram: trigram_config }
        end

        it "passes the custom configuration down to the specified feature" do
          tsearch_feature = instance_double(
            "PgSearch::Features::TSearch",
            conditions: Arel::Nodes::Grouping.new(Arel.sql("1 = 1")),
            rank: Arel::Nodes::Grouping.new(Arel.sql("1.0"))
          )

          trigram_feature = instance_double(
            "PgSearch::Features::Trigram",
            conditions: Arel::Nodes::Grouping.new(Arel.sql("1 = 1")),
            rank: Arel::Nodes::Grouping.new(Arel.sql("1.0"))
          )

          allow(PgSearch::Features::TSearch).to receive(:new).with(anything, tsearch_config, anything, anything, anything).and_return(tsearch_feature)
          allow(PgSearch::Features::Trigram).to receive(:new).with(anything, trigram_config, anything, anything, anything).and_return(trigram_feature)

          ModelWithPgSearch.with_tsearch_and_trigram_using_hash("foo")

          expect(PgSearch::Features::TSearch).to have_received(:new).with(anything, tsearch_config, anything, anything, anything).at_least(:once)
          expect(PgSearch::Features::Trigram).to have_received(:new).with(anything, trigram_config, anything, anything, anything).at_least(:once)
        end
      end
    end

    context "when using a tsvector column and an association" do
      with_model :Comment do
        table do |t|
          t.integer :post_id
          t.string :body
        end

        model do
          belongs_to :post
        end
      end

      with_model :Post do
        table do |t|
          t.text 'content'
          t.tsvector 'content_tsvector'
        end

        model do
          include PgSearch::Model
          has_many :comments
        end
      end

      let!(:expected) { Post.create!(content: 'phooey') }
      let!(:unexpected) { Post.create!(content: 'longcat is looooooooong') }

      before do
        ActiveRecord::Base.connection.execute <<~SQL.squish
          UPDATE #{Post.quoted_table_name}
          SET content_tsvector = to_tsvector('english'::regconfig, #{Post.quoted_table_name}."content")
        SQL

        expected.comments.create(body: 'commentone')
        unexpected.comments.create(body: 'commentwo')

        Post.pg_search_scope :search_by_content_with_tsvector,
                             associated_against: { comments: [:body] },
                             using: {
                               tsearch: {
                                 tsvector_column: 'content_tsvector',
                                 dictionary: 'english'
                               }
                             }
      end

      it "finds by the tsvector column" do
        expect(Post.search_by_content_with_tsvector("phooey").map(&:id)).to eq([expected.id])
      end

      it "finds by the associated record" do
        expect(Post.search_by_content_with_tsvector("commentone").map(&:id)).to eq([expected.id])
      end

      it 'finds by a combination of the two' do
        expect(Post.search_by_content_with_tsvector("phooey commentone").map(&:id)).to eq([expected.id])
      end
    end

    context 'when using multiple tsvector columns' do
      with_model :ModelWithTsvector do
        model do
          include PgSearch::Model

          pg_search_scope :search_by_multiple_tsvector_columns,
                          against: ['content', 'message'],
                          using: {
                            tsearch: {
                              tsvector_column: ['content_tsvector', 'message_tsvector'],
                              dictionary: 'english'
                            }
                          }
        end
      end

      it 'concats tsvector columns' do
        expected = "#{ModelWithTsvector.quoted_table_name}.\"content_tsvector\" || "\
                   "#{ModelWithTsvector.quoted_table_name}.\"message_tsvector\""

        expect(ModelWithTsvector.search_by_multiple_tsvector_columns("something").to_sql).to include(expected)
      end
    end

    context "when using a tsvector column with" do
      with_model :ModelWithTsvector do
        table do |t|
          t.text 'content'
          t.tsvector 'content_tsvector'
        end

        model { include PgSearch::Model }
      end

      let!(:expected) { ModelWithTsvector.create!(content: 'tiling is grouty') }

      before do
        ModelWithTsvector.create!(content: 'longcat is looooooooong')

        ActiveRecord::Base.connection.execute <<~SQL.squish
          UPDATE #{ModelWithTsvector.quoted_table_name}
          SET content_tsvector = to_tsvector('english'::regconfig, #{ModelWithTsvector.quoted_table_name}."content")
        SQL

        ModelWithTsvector.pg_search_scope :search_by_content_with_tsvector,
                                          against: :content,
                                          using: {
                                            tsearch: {
                                              tsvector_column: 'content_tsvector',
                                              dictionary: 'english'
                                            }
                                          }
      end

      it "does not use to_tsvector in the query" do
        expect(ModelWithTsvector.search_by_content_with_tsvector("tiles").to_sql).not_to match(/to_tsvector/)
      end

      it "finds the expected result" do
        expect(ModelWithTsvector.search_by_content_with_tsvector("tiles").map(&:id)).to eq([expected.id])
      end

      context "when joining to a table with a column of the same name" do
        with_model :AnotherModel do
          table do |t|
            t.string :content_tsvector # the type of the column doesn't matter
            t.belongs_to :model_with_tsvector, index: false
          end
        end

        before do
          ModelWithTsvector.has_many :another_models
        end

        it "refers to the tsvector column in the query unambiguously" do
          expect {
            ModelWithTsvector.joins(:another_models).search_by_content_with_tsvector("test").to_a
          }.not_to raise_exception
        end
      end
    end

    context "when ignoring accents" do
      before do
        ModelWithPgSearch.pg_search_scope :search_title_without_accents,
                                          against: :title,
                                          ignoring: :accents
      end

      it "returns rows that match the query but not its accents" do
        # \303\241 is a with acute accent
        # \303\251 is e with acute accent

        included = ModelWithPgSearch.create!(title: "\303\241bcdef")

        results = ModelWithPgSearch.search_title_without_accents("abcd\303\251f")
        expect(results).to eq([included])
      end

      context "when the query includes accents" do
        it "does not create an erroneous tsquery expression" do
          included = ModelWithPgSearch.create!(title: "Weird L‘Content")

          results = ModelWithPgSearch.search_title_without_accents("L‘Content")
          expect(results).to eq([included])
        end
      end
    end

    context "when passed a :ranked_by expression" do
      before do
        ModelWithPgSearch.pg_search_scope :search_content_with_default_rank,
                                          against: :content

        ModelWithPgSearch.pg_search_scope :search_content_with_importance_as_rank,
                                          against: :content,
                                          ranked_by: "importance"

        ModelWithPgSearch.pg_search_scope :search_content_with_importance_as_rank_multiplier,
                                          against: :content,
                                          ranked_by: ":tsearch * importance"
      end

      it "returns records with a rank attribute equal to the :ranked_by expression" do
        ModelWithPgSearch.create!(content: 'foo', importance: 10)
        results = ModelWithPgSearch.search_content_with_importance_as_rank("foo").with_pg_search_rank
        expect(results.first.pg_search_rank).to eq(10)
      end

      it "substitutes :tsearch with the tsearch rank expression in the :ranked_by expression" do
        ModelWithPgSearch.create!(content: 'foo', importance: 10)

        tsearch_result =
          ModelWithPgSearch.search_content_with_default_rank("foo").with_pg_search_rank.first

        tsearch_rank = tsearch_result.pg_search_rank

        multiplied_result =
          ModelWithPgSearch.search_content_with_importance_as_rank_multiplier("foo")
                           .with_pg_search_rank
                           .first

        multiplied_rank = multiplied_result.pg_search_rank

        expect(multiplied_rank).to be_within(0.001).of(tsearch_rank * 10)
      end

      it "returns results in descending order of the value of the rank expression" do
        records = [
          ModelWithPgSearch.create!(content: 'foo', importance: 1),
          ModelWithPgSearch.create!(content: 'foo', importance: 3),
          ModelWithPgSearch.create!(content: 'foo', importance: 2)
        ]

        results = ModelWithPgSearch.search_content_with_importance_as_rank("foo")
        expect(results).to eq(records.sort_by(&:importance).reverse)
      end

      %w[tsearch trigram dmetaphone].each do |feature|
        context "using the #{feature} ranking algorithm" do
          let(:scope_name) { :"search_content_ranked_by_#{feature}" }

          before do
            ModelWithPgSearch.pg_search_scope scope_name,
                                              against: :content,
                                              ranked_by: ":#{feature}"

            ModelWithPgSearch.create!(content: 'foo')
          end

          context "when .with_pg_search_rank is chained after" do
            specify "its results respond to #pg_search_rank" do
              result = ModelWithPgSearch.send(scope_name, 'foo').with_pg_search_rank.first
              expect(result).to respond_to(:pg_search_rank)
            end

            it "returns the rank when #pg_search_rank is called on a result" do
              results = ModelWithPgSearch.send(scope_name, 'foo').with_pg_search_rank
              expect(results.first.pg_search_rank).to be_a Float
            end
          end

          context "when .with_pg_search_rank is not chained after" do
            specify "its results do not respond to #pg_search_rank" do
              result = ModelWithPgSearch.send(scope_name, 'foo').first
              expect(result).not_to respond_to(:pg_search_rank)
            end

            it "raises PgSearch::PgSearchRankNotSelected when #pg_search_rank is called on a result" do
              result = ModelWithPgSearch.send(scope_name, 'foo').first
              expect {
                result.pg_search_rank
              }.to raise_exception(PgSearch::PgSearchRankNotSelected)
            end
          end
        end
      end

      context "when using the tsearch ranking algorithm" do
        it "sorts results by the tsearch rank" do
          ModelWithPgSearch.pg_search_scope :search_content_ranked_by_tsearch,
                                            using: :tsearch,
                                            against: :content,
                                            ranked_by: ":tsearch"

          once = ModelWithPgSearch.create!(content: 'foo bar')
          twice = ModelWithPgSearch.create!(content: 'foo foo')

          results = ModelWithPgSearch.search_content_ranked_by_tsearch('foo')
          expect(results.find_index(twice)).to be < results.find_index(once)
        end
      end

      context "when using the trigram ranking algorithm" do
        it "sorts results by the trigram rank" do
          ModelWithPgSearch.pg_search_scope :search_content_ranked_by_trigram,
                                            using: :trigram,
                                            against: :content,
                                            ranked_by: ":trigram"

          close = ModelWithPgSearch.create!(content: 'abcdef')
          exact = ModelWithPgSearch.create!(content: 'abc')

          results = ModelWithPgSearch.search_content_ranked_by_trigram('abc')
          expect(results.find_index(exact)).to be < results.find_index(close)
        end
      end

      context "when using the dmetaphone ranking algorithm" do
        it "sorts results by the dmetaphone rank" do
          ModelWithPgSearch.pg_search_scope :search_content_ranked_by_dmetaphone,
                                            using: :dmetaphone,
                                            against: :content,
                                            ranked_by: ":dmetaphone"

          once = ModelWithPgSearch.create!(content: 'Phoo Bar')
          twice = ModelWithPgSearch.create!(content: 'Phoo Fu')

          results = ModelWithPgSearch.search_content_ranked_by_dmetaphone('foo')
          expect(results.find_index(twice)).to be < results.find_index(once)
        end
      end
    end

    context "when there is a sort only feature" do
      it "excludes that feature from the conditions, but uses it in the sorting" do
        ModelWithPgSearch.pg_search_scope :search_content_ranked_by_dmetaphone,
                                          against: :content,
                                          using: {
                                            tsearch: { any_word: true, prefix: true },
                                            dmetaphone: { any_word: true, prefix: true, sort_only: true }
                                          },
                                          ranked_by: ":tsearch + (0.5 * :dmetaphone)"

        exact = ModelWithPgSearch.create!(content: "ash hines")
        one_exact_one_close = ModelWithPgSearch.create!(content: "ash heinz")
        one_exact = ModelWithPgSearch.create!(content: "ash smith")
        one_close = ModelWithPgSearch.create!(content: "leigh heinz")

        results = ModelWithPgSearch.search_content_ranked_by_dmetaphone("ash hines")
        expect(results).to eq [exact, one_exact_one_close, one_exact]
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups
