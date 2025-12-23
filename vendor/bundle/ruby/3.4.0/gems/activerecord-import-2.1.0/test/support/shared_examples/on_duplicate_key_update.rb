# frozen_string_literal: true

def should_support_basic_on_duplicate_key_update
  describe "#import" do
    extend ActiveSupport::TestCase::ImportAssertions

    macro(:perform_import) { raise "supply your own #perform_import in a context below" }
    macro(:updated_topic) { Topic.find(@topic.id) }

    context "with lock_version upsert" do
      describe 'optimistic lock' do
        it 'lock_version upsert after on_duplcate_key_update by model' do
          users = [
            User.new(name: 'Salomon'),
            User.new(name: 'Nathan')
          ]
          User.import(users)
          assert User.count == users.length
          User.all.each do |user|
            assert_equal 0, user.lock_version
          end
          updated_users = User.all.map do |user|
            user.name += ' Rothschild'
            user
          end
          User.import(updated_users, on_duplicate_key_update: [:name])
          assert User.count == updated_users.length
          User.all.each_with_index do |user, i|
            assert_equal user.name, "#{users[i].name} Rothschild"
            assert_equal 1, user.lock_version
          end
        end

        it 'lock_version upsert after on_duplcate_key_update by array' do
          users = [
            User.new(name: 'Salomon'),
            User.new(name: 'Nathan')
          ]
          User.import(users)
          assert User.count == users.length
          User.all.each do |user|
            assert_equal 0, user.lock_version
          end

          columns = [:id, :name]
          updated_values = User.all.map do |user|
            user.name += ' Rothschild'
            [user.id, user.name]
          end
          User.import(columns, updated_values, on_duplicate_key_update: [:name])
          assert User.count == updated_values.length
          User.all.each_with_index do |user, i|
            assert_equal user.name, "#{users[i].name} Rothschild"
            assert_equal 1, user.lock_version
          end
        end

        it 'lock_version upsert after on_duplcate_key_update by hash' do
          users = [
            User.new(name: 'Salomon'),
            User.new(name: 'Nathan')
          ]
          User.import(users)
          assert User.count == users.length
          User.all.each do |user|
            assert_equal 0, user.lock_version
          end
          updated_values = User.all.map do |user|
            user.name += ' Rothschild'
            { id: user.id, name: user.name }
          end
          User.import(updated_values, on_duplicate_key_update: [:name])
          assert User.count == updated_values.length
          User.all.each_with_index do |user, i|
            assert_equal user.name, "#{users[i].name} Rothschild"
            assert_equal 1, user.lock_version
          end
          updated_values2 = User.all.map do |user|
            user.name += ' jr.'
            { id: user.id, name: user.name }
          end
          User.import(updated_values2, on_duplicate_key_update: [:name])
          assert User.count == updated_values2.length
          User.all.each_with_index do |user, i|
            assert_equal user.name, "#{users[i].name} Rothschild jr."
            assert_equal 2, user.lock_version
          end
        end

        it 'upsert optimistic lock columns other than lock_version by model' do
          accounts = [
            Account.new(name: 'Salomon'),
            Account.new(name: 'Nathan')
          ]
          Account.import(accounts)
          assert Account.count == accounts.length
          Account.all.each do |user|
            assert_equal 0, user.lock
          end
          updated_accounts = Account.all.map do |user|
            user.name += ' Rothschild'
            user
          end
          Account.import(updated_accounts, on_duplicate_key_update: [:id, :name])
          assert Account.count == updated_accounts.length
          Account.all.each_with_index do |user, i|
            assert_equal user.name, "#{accounts[i].name} Rothschild"
            assert_equal 1, user.lock
          end
        end

        it 'upsert optimistic lock columns other than lock_version by array' do
          accounts = [
            Account.new(name: 'Salomon'),
            Account.new(name: 'Nathan')
          ]
          Account.import(accounts)
          assert Account.count == accounts.length
          Account.all.each do |user|
            assert_equal 0, user.lock
          end

          columns = [:id, :name]
          updated_values = Account.all.map do |user|
            user.name += ' Rothschild'
            [user.id, user.name]
          end
          Account.import(columns, updated_values, on_duplicate_key_update: [:name])
          assert Account.count == updated_values.length
          Account.all.each_with_index do |user, i|
            assert_equal user.name, "#{accounts[i].name} Rothschild"
            assert_equal 1, user.lock
          end
        end

        it 'upsert optimistic lock columns other than lock_version by hash' do
          accounts = [
            Account.new(name: 'Salomon'),
            Account.new(name: 'Nathan')
          ]
          Account.import(accounts)
          assert Account.count == accounts.length
          Account.all.each do |user|
            assert_equal 0, user.lock
          end
          updated_values = Account.all.map do |user|
            user.name += ' Rothschild'
            { id: user.id, name: user.name }
          end
          Account.import(updated_values, on_duplicate_key_update: [:name])
          assert Account.count == updated_values.length
          Account.all.each_with_index do |user, i|
            assert_equal user.name, "#{accounts[i].name} Rothschild"
            assert_equal 1, user.lock
          end
        end

        it 'update the lock_version of models separated by namespaces by model' do
          makers = [
            Bike::Maker.new(name: 'Yamaha'),
            Bike::Maker.new(name: 'Honda')
          ]
          Bike::Maker.import(makers)
          assert Bike::Maker.count == makers.length
          Bike::Maker.all.each do |maker|
            assert_equal 0, maker.lock_version
          end
          updated_makers = Bike::Maker.all.map do |maker|
            maker.name += ' bikes'
            maker
          end
          Bike::Maker.import(updated_makers, on_duplicate_key_update: [:name])
          assert Bike::Maker.count == updated_makers.length
          Bike::Maker.all.each_with_index do |maker, i|
            assert_equal maker.name, "#{makers[i].name} bikes"
            assert_equal 1, maker.lock_version
          end
        end

        it 'update the lock_version of models separated by namespaces by array' do
          makers = [
            Bike::Maker.new(name: 'Yamaha'),
            Bike::Maker.new(name: 'Honda')
          ]
          Bike::Maker.import(makers)
          assert Bike::Maker.count == makers.length
          Bike::Maker.all.each do |maker|
            assert_equal 0, maker.lock_version
          end

          columns = [:id, :name]
          updated_values = Bike::Maker.all.map do |maker|
            maker.name += ' bikes'
            [maker.id, maker.name]
          end
          Bike::Maker.import(columns, updated_values, on_duplicate_key_update: [:name])
          assert Bike::Maker.count == updated_values.length
          Bike::Maker.all.each_with_index do |maker, i|
            assert_equal maker.name, "#{makers[i].name} bikes"
            assert_equal 1, maker.lock_version
          end
        end

        it 'update the lock_version of models separated by namespaces by hash' do
          makers = [
            Bike::Maker.new(name: 'Yamaha'),
            Bike::Maker.new(name: 'Honda')
          ]
          Bike::Maker.import(makers)
          assert Bike::Maker.count == makers.length
          Bike::Maker.all.each do |maker|
            assert_equal 0, maker.lock_version
          end
          updated_values = Bike::Maker.all.map do |maker|
            maker.name += ' bikes'
            { id: maker.id, name: maker.name }
          end
          Bike::Maker.import(updated_values, on_duplicate_key_update: [:name])
          assert Bike::Maker.count == updated_values.length
          Bike::Maker.all.each_with_index do |maker, i|
            assert_equal maker.name, "#{makers[i].name} bikes"
            assert_equal 1, maker.lock_version
          end
        end
      end

      context 'with locking disabled' do
        it 'does not update the lock_version' do
          users = [
            User.new(name: 'Salomon'),
            User.new(name: 'Nathan')
          ]
          User.import(users)
          assert User.count == users.length
          User.all.each do |user|
            assert_equal 0, user.lock_version
          end
          updated_users = User.all.map do |user|
            user.name += ' Rothschild'
            user
          end

          ActiveRecord::Base.lock_optimistically = false # Disable locking
          User.import(updated_users, on_duplicate_key_update: [:name])
          ActiveRecord::Base.lock_optimistically = true # Enable locking

          assert User.count == updated_users.length
          User.all.each_with_index do |user, i|
            assert_equal user.name, "#{users[i].name} Rothschild"
            assert_equal 0, user.lock_version
          end
        end
      end
    end

    context "with :on_duplicate_key_update" do
      describe 'using :all' do
        let(:columns) { %w( id title author_name author_email_address parent_id ) }
        let(:updated_values) { [[99, "Book - 2nd Edition", "Jane Doe", "janedoe@example.com", 57]] }

        macro(:perform_import) do |*opts|
          Topic.import columns, updated_values, opts.extract_options!.merge(on_duplicate_key_update: :all, validate: false)
        end

        setup do
          values = [[99, "Book", "John Doe", "john@doe.com", 17, 3]]
          Topic.import columns + ['replies_count'], values, validate: false
        end

        it 'updates all specified columns' do
          perform_import
          updated_topic = Topic.find(99)
          assert_equal 'Book - 2nd Edition', updated_topic.title
          assert_equal 'Jane Doe', updated_topic.author_name
          assert_equal 'janedoe@example.com', updated_topic.author_email_address
          assert_equal 57, updated_topic.parent_id
          assert_equal 3, updated_topic.replies_count
        end
      end

      describe "argument safety" do
        it "should not modify the passed in :on_duplicate_key_update array" do
          assert_nothing_raised do
            columns = %w(title author_name).freeze
            Topic.import columns, [%w(foo, bar)], on_duplicate_key_update: columns
          end
        end
      end

      context "with timestamps enabled" do
        let(:time) { Chronic.parse("5 minutes from now") }

        it 'should not overwrite changed updated_at with current timestamp' do
          topic = Topic.create(author_name: "Jane Doe", title: "Book")
          timestamp = Time.now.utc
          topic.updated_at = timestamp
          Topic.import [topic], on_duplicate_key_update: :all, validate: false
          assert_equal timestamp.to_s, Topic.last.updated_at.to_s
        end

        it 'should update updated_at with current timestamp' do
          topic = Topic.create(author_name: "Jane Doe", title: "Book")
          Timecop.freeze(time) do
            Topic.import [topic], on_duplicate_key_update: [:updated_at], validate: false
            assert_in_delta time.to_i, topic.reload.updated_at.to_i, 1.second
          end
        end
      end

      context "with validation checks turned off" do
        asssertion_group(:should_support_on_duplicate_key_update) do
          should_not_update_fields_not_mentioned
          should_update_foreign_keys
          should_not_update_created_at_on_timestamp_columns
          should_update_updated_at_on_timestamp_columns
        end

        let(:columns) { %w( id title author_name author_email_address parent_id ) }
        let(:values) { [[99, "Book", "John Doe", "john@doe.com", 17]] }
        let(:updated_values) { [[99, "Book - 2nd Edition", "Author Should Not Change", "johndoe@example.com", 57]] }

        macro(:perform_import) do |*opts|
          Topic.import columns, updated_values, opts.extract_options!.merge(on_duplicate_key_update: update_columns, validate: false)
        end

        setup do
          Topic.import columns, values, validate: false
          @topic = Topic.find 99
        end

        context "using an empty array" do
          let(:update_columns) { [] }
          should_not_update_fields_not_mentioned
          should_update_updated_at_on_timestamp_columns
        end

        context "using string column names" do
          let(:update_columns) { %w(title author_email_address parent_id) }
          should_support_on_duplicate_key_update
          should_update_fields_mentioned
        end

        context "using symbol column names" do
          let(:update_columns) { [:title, :author_email_address, :parent_id] }
          should_support_on_duplicate_key_update
          should_update_fields_mentioned
        end

        context "using column aliases" do
          let(:columns) { %w( id title author_name author_email_address parent_id ) }
          let(:update_columns) { %w(title author_email_address parent_id) }

          context "with column aliases in column list" do
            let(:columns) { %w( id name author_name author_email_address parent_id ) }
            should_support_on_duplicate_key_update
            should_update_fields_mentioned
          end

          context "with column aliases in update columns list" do
            let(:update_columns) { %w(name author_email_address parent_id) }
            should_support_on_duplicate_key_update
            should_update_fields_mentioned
          end
        end

        if ENV['AR_VERSION'].to_i >= 6.0
          context "using ignored columns" do
            let(:columns) { %w( id title author_name author_email_address parent_id priority ) }
            let(:values) { [[99, "Book", "John Doe", "john@doe.com", 17, 1]] }
            let(:update_columns) { %w(name author_email_address parent_id priority) }
            let(:updated_values) { [[99, "Book - 2nd Edition", "Author Should Not Change", "johndoe@example.com", 57, 2]] }
            should_support_on_duplicate_key_update
            should_update_fields_mentioned
          end
        end
      end

      context "with a table that has a non-standard primary key" do
        let(:columns) { [:promotion_id, :code] }
        let(:values) { [[1, 'DISCOUNT1']] }
        let(:updated_values) { [[1, 'DISCOUNT2']] }
        let(:update_columns) { [:code] }

        macro(:perform_import) do |*opts|
          Promotion.import columns, updated_values, opts.extract_options!.merge(on_duplicate_key_update: update_columns, validate: false)
        end
        macro(:updated_promotion) { Promotion.find(@promotion.promotion_id) }

        setup do
          Promotion.import columns, values, validate: false
          @promotion = Promotion.find 1
        end

        it "should update specified columns" do
          perform_import
          assert_equal 'DISCOUNT2', updated_promotion.code
        end
      end

      unless ENV["SKIP_COMPOSITE_PK"]
        context "with composite primary keys" do
          it "should import array of values successfully" do
            columns = [:tag_id, :publisher_id, :tag]
            Tag.import columns, [[1, 1, 'Mystery']], validate: false

            assert_difference "Tag.count", +0 do
              Tag.import columns, [[1, 1, 'Science']], on_duplicate_key_update: [:tag], validate: false
            end
            assert_equal 'Science', Tag.first.tag
          end
        end
      end
    end

    context "with :on_duplicate_key_update turned off" do
      let(:columns) { %w( id title author_name author_email_address parent_id ) }
      let(:values) { [[100, "Book", "John Doe", "john@doe.com", 17]] }
      let(:updated_values) { [[100, "Book - 2nd Edition", "This should raise an exception", "john@nogo.com", 57]] }

      macro(:perform_import) do |*opts|
        # `on_duplicate_key_update: false` is the tested feature
        Topic.import columns, updated_values, opts.extract_options!.merge(on_duplicate_key_update: false, validate: false)
      end

      setup do
        Topic.import columns, values, validate: false
        @topic = Topic.find 100
      end

      it "should raise ActiveRecord::RecordNotUnique" do
        assert_raise ActiveRecord::RecordNotUnique do
          perform_import
        end
      end
    end
  end
end
