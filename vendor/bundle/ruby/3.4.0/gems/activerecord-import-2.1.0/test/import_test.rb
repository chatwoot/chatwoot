# frozen_string_literal: true

require File.expand_path('../test_helper', __FILE__)

describe "#import" do
  it "should return the number of inserts performed" do
    # see ActiveRecord::ConnectionAdapters::AbstractAdapter test for more specifics
    assert_difference "Topic.count", +10 do
      result = Topic.import Build(3, :topics)
      assert result.num_inserts > 0

      result = Topic.import Build(7, :topics)
      assert result.num_inserts > 0
    end
  end

  it "warns you that you're using the library wrong" do
    error = assert_raise(ArgumentError) { Topic.import %w(title author_name), ['Author #1', 'Book #1', 0] }
    assert_equal error.message, "Last argument should be a two dimensional array '[[]]'. First element in array was a String"
  end

  it "warns you that you're passing more data than you ought to" do
    error = assert_raise(ArgumentError) { Topic.import %w(title author_name), [['Author #1', 'Book #1', 0]] }
    assert_equal error.message, "Number of values (8) exceeds number of columns (7)"
  end

  it "should not produce an error when importing empty arrays" do
    assert_nothing_raised do
      Topic.import []
      Topic.import %w(title author_name), []
    end
  end

  describe "argument safety" do
    it "should not modify the passed in columns array" do
      assert_nothing_raised do
        columns = %w(title author_name).freeze
        Topic.import columns, [%w(foo bar)]
      end
    end

    it "should not modify the passed in values array" do
      assert_nothing_raised do
        record = %w(foo bar).freeze
        values = [record].freeze
        Topic.import %w(title author_name), values
      end
    end
  end

  describe "with non-default ActiveRecord models" do
    context "that have a non-standard primary key (that is no sequence)" do
      it "should import models successfully" do
        assert_difference "Widget.count", +3 do
          Widget.import Build(3, :widgets)
        end
      end

      context "with uppercase letters" do
        it "should import models successfully" do
          assert_difference "Car.count", +3 do
            Car.import Build(3, :cars)
          end
        end
      end
    end

    context "that have no primary key" do
      it "should import models successfully" do
        assert_difference "Rule.count", +3 do
          Rule.import Build(3, :rules)
        end
      end
    end
  end

  describe "with an array of hashes" do
    let(:columns) { [:title, :author_name] }
    let(:values) { [{ title: "LDAP", author_name: "Jerry Carter", author_email_address: "jcarter@test.com" }, { title: "Rails Recipes", author_name: "Chad Fowler", author_email_address: "cfowler@test.com" }] }

    it "should import hash data successfully" do
      assert_difference "Topic.count", +2 do
        Topic.import values, validate: false
      end
    end

    it "should import specified hash data successfully" do
      assert_difference "Topic.count", +2 do
        Topic.import columns, values, validate: false
      end

      Topic.all.each do |t|
        assert_nil t.author_email_address
      end
    end

    context "with extra keys" do
      let(:values) do
        [
          { title: "LDAP", author_name: "Jerry Carter" },
          { title: "Rails Recipes", author_name: "Chad Fowler", author_email_address: "cfowler@test.com" } # author_email_address is unknown
        ]
      end

      it "should fail when column names are not specified" do
        err = assert_raises ArgumentError do
          Topic.import values, validate: false
        end

        assert err.message.include? 'Extra keys: [:author_email_address]'
      end

      it "should succeed when column names are specified" do
        assert_difference "Topic.count", +2 do
          Topic.import columns, values, validate: false
        end
      end
    end

    context "with missing keys" do
      let(:values) do
        [
          { title: "LDAP", author_name: "Jerry Carter" },
          { title: "Rails Recipes" } # author_name is missing
        ]
      end

      it "should fail when column names are not specified" do
        err = assert_raises ArgumentError do
          Topic.import values, validate: false
        end

        assert err.message.include? 'Missing keys: [:author_name]'
      end

      it "should fail on missing hash key from specified column names" do
        err = assert_raises ArgumentError do
          Topic.import %i(author_name), values, validate: false
        end

        assert err.message.include? 'Missing keys: [:author_name]'
      end
    end
  end

  unless ENV["SKIP_COMPOSITE_PK"]
    describe "with composite primary keys" do
      it "should import models successfully" do
        tags = [Tag.new(tag_id: 1, publisher_id: 1, tag: 'Mystery')]

        assert_difference "Tag.count", +1 do
          Tag.import tags
        end
      end

      it "should import array of values successfully" do
        columns = [:tag_id, :publisher_id, :tag]
        values = [[1, 1, 'Mystery'], [2, 1, 'Science']]

        assert_difference "Tag.count", +2 do
          Tag.import columns, values, validate: false
        end
      end

      it "should import models that are required to belong to models with composite primary keys" do
        tag = Tag.create!(tag_id: 1, publisher_id: 1, tag: 'Mystery')
        valid_tag_alias = TagAlias.new(tag_id: tag.tag_id, parent_id: tag.publisher_id, alias: 'Detective')
        invalid_tag_aliases = [
          TagAlias.new(tag_id: nil, parent_id: nil, alias: 'Detective'),
          TagAlias.new(tag_id: tag.tag_id, parent_id: nil, alias: 'Detective'),
          TagAlias.new(tag_id: nil, parent_id: tag.publisher_id, alias: 'Detective'),
        ]

        assert_difference "TagAlias.count", +1 do
          TagAlias.import [valid_tag_alias]
        end
        invalid_tag_aliases.each do |invalid_tag_alias|
          assert_no_difference "TagAlias.count" do
            TagAlias.import [invalid_tag_alias]
          end
        end
      end
    end
  end

  describe "with STI models" do
    it "should import models successfully" do
      dictionaries = [Dictionary.new(author_name: "Noah Webster", title: "Webster's Dictionary")]

      assert_difference "Dictionary.count", +1 do
        Dictionary.import dictionaries
      end
      assert_equal "Dictionary", Dictionary.last.type
    end

    it "should import arrays successfully" do
      columns = [:author_name, :title]
      values =  [["Noah Webster", "Webster's Dictionary"]]

      assert_difference "Dictionary.count", +1 do
        Dictionary.import columns, values
      end
      assert_equal "Dictionary", Dictionary.last.type
    end
  end

  context "with :validation option" do
    let(:columns) { %w(title author_name content) }
    let(:valid_values) { [["LDAP", "Jerry Carter", "Putting Directories to Work."], ["Rails Recipes", "Chad Fowler", "A trusted collection of solutions."]] }
    let(:valid_values_with_context) { [[1111, "Jerry Carter", "1111"], [2222, "Chad Fowler", "2222"]] }
    let(:invalid_values) { [["The RSpec Book", "David Chelimsky", "..."], ["Agile+UX", "", "All about Agile in UX."]] }
    let(:valid_models) { valid_values.map { |title, author_name, content| Topic.new(title: title, author_name: author_name, content: content) } }
    let(:invalid_models) { invalid_values.map { |title, author_name, content| Topic.new(title: title, author_name: author_name, content: content) } }

    context "with validation checks turned off" do
      it "should import valid data" do
        assert_difference "Topic.count", +2 do
          Topic.import columns, valid_values, validate: false
        end
      end

      it "should import invalid data" do
        assert_difference "Topic.count", +2 do
          Topic.import columns, invalid_values, validate: false
        end
      end

      it 'should raise a specific error if a column does not exist' do
        assert_raises ActiveRecord::Import::MissingColumnError do
          Topic.import ['foo'], [['bar']], validate: false
        end
      end
    end

    context "with validation checks turned on" do
      it "should import valid data" do
        assert_difference "Topic.count", +2 do
          Topic.import columns, valid_values, validate: true
        end
      end

      it "should import valid data with on option" do
        assert_difference "Topic.count", +2 do
          Topic.import columns, valid_values_with_context, validate_with_context: :context_test
        end
      end

      it "should ignore uniqueness validators" do
        Topic.import columns, valid_values
        assert_difference "Topic.count", +2 do
          Topic.import columns, valid_values
        end
      end

      it "should not alter the callback chain of the model" do
        attributes = columns.zip(valid_values.first).to_h
        topic = Topic.new attributes
        Topic.import [topic], validate: true
        duplicate_topic = Topic.new attributes
        Topic.import [duplicate_topic], validate: true
        assert duplicate_topic.invalid?
      end

      it "should not import invalid data" do
        assert_no_difference "Topic.count" do
          Topic.import columns, invalid_values, validate: true
        end
      end

      it "should import invalid data with on option" do
        assert_no_difference "Topic.count" do
          Topic.import columns, valid_values, validate_with_context: :context_test
        end
      end

      it "should report the failed instances" do
        results = Topic.import columns, invalid_values, validate: true
        assert_equal invalid_values.size, results.failed_instances.size
        assert_not_equal results.failed_instances.first, results.failed_instances.last
        results.failed_instances.each do |e|
          assert_kind_of Topic, e
          assert_equal e.errors.count, 1
        end
      end

      it "should index the failed instances by their poistion in the set if `track_failures` is true" do
        index_offset = valid_values.length
        results = Topic.import columns, valid_values + invalid_values, validate: true, track_validation_failures: true
        assert_equal invalid_values.size, results.failed_instances.size
        invalid_values.each_with_index do |value_set, index|
          assert_equal index + index_offset, results.failed_instances[index].first
          assert_equal value_set.first, results.failed_instances[index].last.title
        end
      end

      it "should set ids in valid models if adapter supports setting primary key of imported objects" do
        if ActiveRecord::Base.supports_setting_primary_key_of_imported_objects?
          Topic.import (invalid_models + valid_models), validate: true
          assert_nil invalid_models[0].id
          assert_nil invalid_models[1].id
          assert_equal valid_models[0].id, Topic.all[0].id
          assert_equal valid_models[1].id, Topic.all[1].id
        end
      end

      it "should set ActiveRecord timestamps in valid models if adapter supports setting primary key of imported objects" do
        if ActiveRecord::Base.supports_setting_primary_key_of_imported_objects?
          Timecop.freeze(Time.at(0)) do
            Topic.import (invalid_models + valid_models), validate: true
          end

          assert_nil invalid_models[0].created_at
          assert_nil invalid_models[0].updated_at
          assert_nil invalid_models[1].created_at
          assert_nil invalid_models[1].updated_at

          assert_equal valid_models[0].created_at, Topic.all[0].created_at
          assert_equal valid_models[0].updated_at, Topic.all[0].updated_at
          assert_equal valid_models[1].created_at, Topic.all[1].created_at
          assert_equal valid_models[1].updated_at, Topic.all[1].updated_at
        end
      end

      it "should import valid data when mixed with invalid data" do
        assert_difference "Topic.count", +2 do
          Topic.import columns, valid_values + invalid_values, validate: true
        end
        assert_equal 0, Topic.where(title: invalid_values.map(&:first)).count
      end

      it "should run callbacks" do
        assert_no_difference "Topic.count" do
          Topic.import columns, [["invalid", "Jerry Carter"]], validate: true
        end
      end

      it "should call validation methods" do
        assert_no_difference "Topic.count" do
          Topic.import columns, [["validate_failed", "Jerry Carter"]], validate: true
        end
      end
    end

    context "with uniqueness validators included" do
      it "should not import duplicate records" do
        Topic.import columns, valid_values
        assert_no_difference "Topic.count" do
          Topic.import columns, valid_values, validate_uniqueness: true
        end
      end
    end

    context "when validatoring presence of belongs_to association" do
      it "should not import records without foreign key" do
        assert_no_difference "UserToken.count" do
          UserToken.import [:token], [['12345abcdef67890']]
        end
      end

      it "should import records with foreign key" do
        assert_difference "UserToken.count", +1 do
          UserToken.import [:user_name, :token], [%w("Bob", "12345abcdef67890")]
        end
      end

      it "should not mutate the defined validations" do
        UserToken.import [:user_name, :token], [%w("Bob", "12345abcdef67890")]
        ut = UserToken.new
        ut.valid?
        assert_includes ut.errors.messages, :user
      end
    end
  end

  context "without :validation option" do
    let(:columns) { %w(title author_name) }
    let(:invalid_values) { [["The RSpec Book", ""], ["Agile+UX", ""]] }

    it "should not import invalid data" do
      assert_no_difference "Topic.count" do
        result = Topic.import columns, invalid_values
        assert_equal 2, result.failed_instances.size
      end
    end
  end

  context "with :all_or_none option" do
    let(:columns) { %w(title author_name) }
    let(:valid_values) { [["LDAP", "Jerry Carter"], ["Rails Recipes", "Chad Fowler"]] }
    let(:invalid_values) { [["The RSpec Book", ""], ["Agile+UX", ""]] }
    let(:mixed_values) { valid_values + invalid_values }

    context "with validation checks turned on" do
      it "should import valid data" do
        assert_difference "Topic.count", +2 do
          Topic.import columns, valid_values, all_or_none: true
        end
      end

      it "should not import invalid data" do
        assert_no_difference "Topic.count" do
          Topic.import columns, invalid_values, all_or_none: true
        end
      end

      it "should not import valid data when mixed with invalid data" do
        assert_no_difference "Topic.count" do
          Topic.import columns, mixed_values, all_or_none: true
        end
      end

      it "should report the failed instances" do
        results = Topic.import columns, mixed_values, all_or_none: true
        assert_equal invalid_values.size, results.failed_instances.size
        results.failed_instances.each { |e| assert_kind_of Topic, e }
      end

      it "should report the zero inserts" do
        results = Topic.import columns, mixed_values, all_or_none: true
        assert_equal 0, results.num_inserts
      end
    end
  end

  context "with :batch_size option" do
    it "should import with a single insert" do
      assert_difference "Topic.count", +10 do
        result = Topic.import Build(10, :topics), batch_size: 10
        assert_equal 1, result.num_inserts if Topic.supports_import?
      end
    end

    it "should import with multiple inserts" do
      assert_difference "Topic.count", +10 do
        result = Topic.import Build(10, :topics), batch_size: 4
        assert_equal 3, result.num_inserts if Topic.supports_import?
      end
    end

    it "should accept and call an optional callable to run after each batch" do
      lambda_called = 0

      my_proc = ->(_row_count, _batches, _batch, _duration) { lambda_called += 1 }
      Topic.import Build(10, :topics), batch_size: 4, batch_progress: my_proc

      assert_equal 3, lambda_called
    end
  end

  context "with :synchronize option" do
    context "synchronizing on new records" do
      let(:new_topics) { Build(3, :topics) }

      it "doesn't reload any data (doesn't work)" do
        Topic.import new_topics, synchronize: new_topics
        if Topic.supports_setting_primary_key_of_imported_objects?
          assert new_topics.all?(&:persisted?), "Records should have been reloaded"
        else
          assert new_topics.all?(&:new_record?), "No record should have been reloaded"
        end
      end
    end

    context "synchronizing on new records with explicit conditions" do
      let(:new_topics) { Build(3, :topics) }

      it "reloads data for existing in-memory instances" do
        Topic.import(new_topics, synchronize: new_topics, synchronize_keys: [:title] )
        assert new_topics.all?(&:persisted?), "Records should have been reloaded"
      end
    end

    context "synchronizing on destroyed records with explicit conditions" do
      let(:new_topics) { Generate(3, :topics) }

      it "reloads data for existing in-memory instances" do
        new_topics.each(&:destroy)
        Topic.import(new_topics, synchronize: new_topics, synchronize_keys: [:title] )
        assert new_topics.all?(&:persisted?), "Records should have been reloaded"
      end
    end
  end

  context "with an array of unsaved model instances" do
    let(:topic) { Build(:topic, title: "The RSpec Book", author_name: "David Chelimsky") }
    let(:topics) { Build(9, :topics) }
    let(:invalid_topics) { Build(7, :invalid_topics) }

    it "should import records based on those model's attributes" do
      assert_difference "Topic.count", +9 do
        Topic.import topics
      end

      Topic.import [topic]
      assert Topic.where(title: "The RSpec Book", author_name: "David Chelimsky").first
    end

    it "should not overwrite existing records" do
      topic = Generate(:topic, title: "foobar")
      assert_no_difference "Topic.count" do
        begin
          Topic.transaction do
            topic.title = "baz"
            Topic.import [topic]
          end
        rescue Exception
          # PostgreSQL raises PgError due to key constraints
          # I don't know why ActiveRecord doesn't catch these. *sigh*
        end
      end
      assert_equal "foobar", topic.reload.title
    end

    context "with validation checks turned on" do
      it "should import valid models" do
        assert_difference "Topic.count", +9 do
          Topic.import topics, validate: true
        end
      end

      it "should not import invalid models" do
        assert_no_difference "Topic.count" do
          Topic.import invalid_topics, validate: true
        end
      end
    end

    context "with validation checks turned off" do
      it "should import invalid models" do
        assert_difference "Topic.count", +7 do
          Topic.import invalid_topics, validate: false
        end
      end
    end
  end

  context "with an array of columns and an array of unsaved model instances" do
    let(:topics) { Build(2, :topics) }

    it "should import records populating the supplied columns with the corresponding model instance attributes" do
      assert_difference "Topic.count", +2 do
        Topic.import [:author_name, :title], topics
      end

      # imported topics should be findable by their imported attributes
      assert Topic.where(author_name: topics.first.author_name).first
      assert Topic.where(author_name: topics.last.author_name).first
    end

    it "should not populate fields for columns not imported" do
      topics.first.author_email_address = "zach.dennis@gmail.com"
      assert_difference "Topic.count", +2 do
        Topic.import [:author_name, :title], topics
      end

      assert !Topic.where(author_email_address: "zach.dennis@gmail.com").first
    end
  end

  context "with an array of columns and an array of values" do
    it "should import ids when specified" do
      Topic.import [:id, :author_name, :title], [[99, "Bob Jones", "Topic 99"]]
      assert_equal 99, Topic.last.id
    end

    it "ignores the recursive option" do
      assert_difference "Topic.count", +1 do
        Topic.import [:author_name, :title], [["David Chelimsky", "The RSpec Book"]], recursive: true
      end
    end
  end

  context "ActiveRecord timestamps" do
    let(:time) { Chronic.parse("5 minutes ago") }

    context "when the timestamps columns are present" do
      setup do
        @existing_book = Book.create(title: "Fell", author_name: "Curry", publisher: "Bayer", created_at: 2.years.ago.utc, created_on: 2.years.ago.utc, updated_at: 2.years.ago.utc, updated_on: 2.years.ago.utc)
        if ActiveRecord.respond_to?(:default_timezone)
          ActiveRecord.default_timezone = :utc
        else
          ActiveRecord::Base.default_timezone = :utc
        end
        Timecop.freeze(time) do
          assert_difference "Book.count", +2 do
            Book.import %w(title author_name publisher created_at created_on updated_at updated_on), [["LDAP", "Big Bird", "Del Rey", nil, nil, nil, nil], [@existing_book.title, @existing_book.author_name, @existing_book.publisher, @existing_book.created_at, @existing_book.created_on, @existing_book.updated_at, @existing_book.updated_on]]
          end
        end
        @new_book, @existing_book = Book.last 2
      end

      it "should set the created_at column for new records" do
        assert_in_delta time.to_i, @new_book.created_at.to_i, 1.second
      end

      it "should set the created_on column for new records" do
        assert_in_delta time.to_i, @new_book.created_on.to_i, 1.second
      end

      it "should not set the created_at column for existing records" do
        assert_equal 2.years.ago.utc.strftime("%Y:%d"), @existing_book.created_at.strftime("%Y:%d")
      end

      it "should not set the created_on column for existing records" do
        assert_equal 2.years.ago.utc.strftime("%Y:%d"), @existing_book.created_on.strftime("%Y:%d")
      end

      it "should set the updated_at column for new records" do
        assert_in_delta time.to_i, @new_book.updated_at.to_i, 1.second
      end

      it "should set the updated_on column for new records" do
        assert_in_delta time.to_i, @new_book.updated_on.to_i, 1.second
      end

      it "should not set the updated_at column for existing records" do
        assert_equal 2.years.ago.utc.strftime("%Y:%d"), @existing_book.updated_at.strftime("%Y:%d")
      end

      it "should not set the updated_on column for existing records" do
        assert_equal 2.years.ago.utc.strftime("%Y:%d"), @existing_book.updated_on.strftime("%Y:%d")
      end

      it "should not set the updated_at column on models if changed" do
        timestamp = Time.now.utc
        books = [
          Book.new(author_name: "Foo", title: "Baz", created_at: timestamp, updated_at: timestamp)
        ]
        Book.import books
        assert_equal timestamp.strftime("%Y:%d"), Book.last.updated_at.strftime("%Y:%d")
      end
    end

    context "when a custom time zone is set" do
      setup do
        Timecop.freeze(time) do
          assert_difference "Book.count", +1 do
            Book.import [:title, :author_name, :publisher], [["LDAP", "Big Bird", "Del Rey"]]
          end
        end
        @book = Book.last
      end

      it "should set the created_at and created_on timestamps for new records" do
        assert_in_delta time.to_i, @book.created_at.to_i, 1.second
        assert_in_delta time.to_i, @book.created_on.to_i, 1.second
      end

      it "should set the updated_at and updated_on timestamps for new records" do
        assert_in_delta time.to_i, @book.updated_at.to_i, 1.second
        assert_in_delta time.to_i, @book.updated_on.to_i, 1.second
      end
    end
  end

  context "importing with database reserved words" do
    let(:group) { Build(:group, order: "superx") }

    it "should import just fine" do
      assert_difference "Group.count", +1 do
        Group.import [group]
      end
      assert_equal "superx", Group.first.order
    end
  end

  context "importing a datetime field" do
    it "should import a date with YYYY/MM/DD format just fine" do
      Topic.import [:author_name, :title, :last_read], [["Bob Jones", "Topic 2", "2010/05/14"]]
      assert_equal "2010/05/14".to_date, Topic.last.last_read.to_date
    end
  end

  context "importing through an association scope" do
    { has_many: :chapters, polymorphic: :discounts }.each do |association_type, association|
      book   = FactoryBot.create :book
      scope  = book.public_send association
      klass  = { chapters: Chapter, discounts: Discount }[association]
      column = { chapters: :title,  discounts: :amount  }[association]
      val1   = { chapters: 'A',     discounts: 5        }[association]
      val2   = { chapters: 'B',     discounts: 6        }[association]

      context "for #{association_type}" do
        it "works importing models" do
          scope.import [
            klass.new(column => val1),
            klass.new(column => val2)
          ]

          assert_equal [val1, val2], scope.map(&column).sort
        end

        it "works importing array of columns and values" do
          scope.import [column], [[val1], [val2]]

          assert_equal [val1, val2], scope.map(&column).sort
        end

        context "for cards and decks" do
          it "works when the polymorphic name is different than base class name" do
            deck = Deck.create(id: 1, name: 'test')
            deck.cards.import [:id, :deck_type], [[1, 'PlayingCard']]
            assert_equal deck.cards.first.deck_type, "PlayingCard"
          end
        end

        it "works importing array of hashes" do
          scope.import [{ column => val1 }, { column => val2 }]

          assert_equal [val1, val2], scope.map(&column).sort
        end
      end

      it "works with a non-standard association primary key" do
        user = User.create(id: 1, name: 'Solomon')
        user.user_tokens.import [:id, :token], [[5, '12345abcdef67890']]

        token = UserToken.find(5)
        assert_equal 'Solomon', token.user_name
      end
    end
  end

  context "importing model with polymorphic belongs_to" do
    it "works without error" do
      book     = FactoryBot.create :book
      discount = Discount.new(discountable: book)

      Discount.import([discount])

      assert_equal 1, Discount.count
    end
  end

  context 'When importing models with Enum fields' do
    it 'should be able to import enum fields' do
      Book.delete_all if Book.count > 0
      books = [
        Book.new(author_name: "Foo", title: "Baz", status: 0),
        Book.new(author_name: "Foo2", title: "Baz2", status: 1),
      ]
      Book.import books
      assert_equal 2, Book.count
      assert_equal 'draft', Book.first.read_attribute('status')
      assert_equal 'published', Book.last.read_attribute('status')
    end

    it 'should be able to import enum fields with default value' do
      Book.delete_all if Book.count > 0
      books = [
        Book.new(author_name: "Foo", title: "Baz")
      ]
      Book.import books
      assert_equal 1, Book.count
      assert_equal 'draft', Book.first.read_attribute('status')
    end

    it 'should be able to import enum fields by name' do
      Book.delete_all if Book.count > 0
      books = [
        Book.new(author_name: "Foo", title: "Baz", status: :draft),
        Book.new(author_name: "Foo2", title: "Baz2", status: :published),
      ]
      Book.import books
      assert_equal 2, Book.count
      assert_equal 'draft', Book.first.read_attribute('status')
      assert_equal 'published', Book.last.read_attribute('status')
    end
  end

  context 'When importing arrays of values with Enum fields' do
    let(:columns) { [:author_name, :title, :status] }
    let(:values) { [['Author #1', 'Book #1', 0], ['Author #2', 'Book #2', 1]] }

    it 'should be able to import enum fields' do
      Book.delete_all if Book.count > 0
      Book.import columns, values
      assert_equal 2, Book.count

      assert_equal 'draft', Book.first.read_attribute('status')
      assert_equal 'published', Book.last.read_attribute('status')
    end
  end

  context 'importing arrays of values with boolean fields' do
    let(:columns) { [:author_name, :title, :for_sale] }

    it 'should be able to coerce integers as boolean fields' do
      Book.delete_all if Book.count > 0
      values = [['Author #1', 'Book #1', 0], ['Author #2', 'Book #2', 1]]
      assert_difference "Book.count", +2 do
        Book.import columns, values
      end
      assert_equal false, Book.first.for_sale
      assert_equal true, Book.last.for_sale
    end

    it 'should be able to coerce strings as boolean fields' do
      Book.delete_all if Book.count > 0
      values = [['Author #1', 'Book #1', 'false'], ['Author #2', 'Book #2', 'true']]
      assert_difference "Book.count", +2 do
        Book.import columns, values
      end
      assert_equal false, Book.first.for_sale
      assert_equal true, Book.last.for_sale
    end
  end

  describe "importing when model has default_scope" do
    it "doesn't import the default scope values" do
      assert_difference "Widget.unscoped.count", +2 do
        Widget.import [:w_id], [[1], [2]]
      end
      default_scope_value = Widget.scope_attributes[:active]
      assert_not_equal default_scope_value, Widget.unscoped.find_by_w_id(1)
      assert_not_equal default_scope_value, Widget.unscoped.find_by_w_id(2)
    end

    it "imports columns that are a part of the default scope using the value specified" do
      assert_difference "Widget.unscoped.count", +2 do
        Widget.import [:w_id, :active], [[1, true], [2, false]]
      end
      assert_not_equal true, Widget.unscoped.find_by_w_id(1)
      assert_not_equal false, Widget.unscoped.find_by_w_id(2)
    end
  end

  describe "importing serialized fields" do
    it "imports values for serialized Hash fields" do
      assert_difference "Widget.unscoped.count", +1 do
        Widget.import [:w_id, :data], [[1, { a: :b }]]
      end
      assert_equal({ a: :b }, Widget.find_by_w_id(1).data)
    end

    it "imports values for serialized fields" do
      assert_difference "Widget.unscoped.count", +1 do
        Widget.import [:w_id, :unspecified_data], [[1, { a: :b }]]
      end
      assert_equal({ a: :b }, Widget.find_by_w_id(1).unspecified_data)
    end

    it "imports values for custom coder" do
      assert_difference "Widget.unscoped.count", +1 do
        Widget.import [:w_id, :custom_data], [[1, { a: :b }]]
      end
      assert_equal({ a: :b }, Widget.find_by_w_id(1).custom_data)
    end

    let(:data) { { a: :b } }
    it "imports values for serialized JSON fields" do
      assert_difference "Widget.unscoped.count", +1 do
        Widget.import [:w_id, :json_data], [[9, data]]
      end
      assert_equal(data.as_json, Widget.find_by_w_id(9).json_data)
    end

    it "imports serialized values from saved records" do
      Widget.import [:w_id, :json_data], [[1, data]]
      assert_equal data.as_json, Widget.last.json_data

      w = Widget.last
      w.w_id = 2
      Widget.import([w])
      assert_equal data.as_json, Widget.last.json_data
    end

    context "with a store" do
      it "imports serialized attributes set using accessors" do
        vendors = [Vendor.new(name: 'Vendor 1', color: 'blue')]
        assert_difference "Vendor.count", +1 do
          Vendor.import vendors
        end
        assert_equal('blue', Vendor.first.color)
      end
    end
  end

  describe "#import!" do
    context "with an array of unsaved model instances" do
      let(:topics) { Build(2, :topics) }
      let(:invalid_topics) { Build(2, :invalid_topics) }

      context "with invalid data" do
        it "should raise ActiveRecord::RecordInvalid" do
          assert_no_difference "Topic.count" do
            assert_raise ActiveRecord::RecordInvalid do
              Topic.import! invalid_topics
            end
          end
        end
      end

      context "with valid data" do
        it "should import data" do
          assert_difference "Topic.count", +2 do
            Topic.import! topics
          end
        end
      end
    end

    context "with array of columns and array of values" do
      let(:columns) { %w(title author_name) }
      let(:valid_values) { [["LDAP", "Jerry Carter"], ["Rails Recipes", "Chad Fowler"]] }
      let(:invalid_values) { [["Rails Recipes", "Chad Fowler"], ["The RSpec Book", ""], ["Agile+UX", ""]] }

      context "with invalid data" do
        it "should raise ActiveRecord::RecordInvalid" do
          assert_no_difference "Topic.count" do
            assert_raise ActiveRecord::RecordInvalid do
              Topic.import! columns, invalid_values
            end
          end
        end
      end

      context "with valid data" do
        it "should import data" do
          assert_difference "Topic.count", +2 do
            Topic.import! columns, valid_values
          end
        end
      end
    end

    context "with objects that respond to .to_sql as values" do
      let(:columns) { %w(title author_name) }
      let(:valid_values) { [["LDAP", Book.select("'Jerry Carter'").limit(1)], ["Rails Recipes", Book.select("'Chad Fowler'").limit(1)]] }

      it "should import data" do
        assert_difference "Topic.count", +2 do
          Topic.import! columns, valid_values
          topics = Topic.all
          assert_equal "Jerry Carter", topics.first.author_name
          assert_equal "Chad Fowler", topics.last.author_name
        end
      end
    end
  end
  describe "importing model with after_initialize callback" do
    let(:columns) { %w(name size) }
    let(:valid_values) { [%w("Deer", "Small"), %w("Monkey", "Medium")] }
    let(:invalid_values) do
      [
        { name: "giraffe", size: "Large" },
        { size: "Medium" } # name is missing
      ]
    end
    context "with validation checks turned off" do
      it "should import valid data" do
        Animal.import(columns, valid_values, validate: false)
        assert_equal 2, Animal.count
      end
      it "should raise ArgumentError" do
        assert_raise(ArgumentError) { Animal.import(invalid_values, validate: false) }
      end
    end

    context "with validation checks turned on" do
      it "should import valid data" do
        Animal.import(columns, valid_values, validate: true)
        assert_equal 2, Animal.count
      end
      it "should raise ArgumentError" do
        assert_raise(ArgumentError) { Animal.import(invalid_values, validate: true) }
      end
    end
  end
end
