require 'active_support/core_ext/module/delegation'

module Shoulda
  module Matchers
    module ActiveRecord
      # The `belong_to` matcher is used to ensure that a `belong_to` association
      # exists on your model.
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :organization
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should belong_to(:organization) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should belong_to(:organization)
      #     end
      #
      # Note that polymorphic associations are automatically detected and do not
      # need any qualifiers:
      #
      #     class Comment < ActiveRecord::Base
      #       belongs_to :commentable, polymorphic: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Comment, type: :model do
      #       it { should belong_to(:commentable) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class CommentTest < ActiveSupport::TestCase
      #       should belong_to(:commentable)
      #     end
      #
      # #### Qualifiers
      #
      # ##### conditions
      #
      # Use `conditions` if your association is defined with a scope that sets
      # the `where` clause.
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :family, -> { where(everyone_is_perfect: false) }
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should belong_to(:family).
      #           conditions(everyone_is_perfect: false)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should belong_to(:family).
      #         conditions(everyone_is_perfect: false)
      #     end
      #
      # ##### order
      #
      # Use `order` if your association is defined with a scope that sets the
      # `order` clause.
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :previous_company, -> { order('hired_on desc') }
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should belong_to(:previous_company).order('hired_on desc') }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should belong_to(:previous_company).order('hired_on desc')
      #     end
      #
      # ##### class_name
      #
      # Use `class_name` to test usage of the `:class_name` option. This
      # asserts that the model you're referring to actually exists.
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :ancient_city, class_name: 'City'
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should belong_to(:ancient_city).class_name('City') }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should belong_to(:ancient_city).class_name('City')
      #     end
      #
      # ##### with_primary_key
      #
      # Use `with_primary_key` to test usage of the `:primary_key` option.
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :great_country, primary_key: 'country_id'
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should belong_to(:great_country).
      #           with_primary_key('country_id')
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should belong_to(:great_country).
      #         with_primary_key('country_id')
      #     end
      #
      # ##### with_foreign_key
      #
      # Use `with_foreign_key` to test usage of the `:foreign_key` option.
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :great_country, foreign_key: 'country_id'
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should belong_to(:great_country).
      #           with_foreign_key('country_id')
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should belong_to(:great_country).
      #         with_foreign_key('country_id')
      #     end
      #
      # ##### dependent
      #
      # Use `dependent` to assert that the `:dependent` option was specified.
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :world, dependent: :destroy
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should belong_to(:world).dependent(:destroy) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should belong_to(:world).dependent(:destroy)
      #     end
      #
      # To assert that *any* `:dependent` option was specified, use `true`:
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should belong_to(:world).dependent(true) }
      #     end
      #
      # To assert that *no* `:dependent` option was specified, use `false`:
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :company
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should belong_to(:company).dependent(false) }
      #     end
      #
      # ##### counter_cache
      #
      # Use `counter_cache` to assert that the `:counter_cache` option was
      # specified.
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :organization, counter_cache: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should belong_to(:organization).counter_cache(true) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should belong_to(:organization).counter_cache(true)
      #     end
      #
      # ##### touch
      #
      # Use `touch` to assert that the `:touch` option was specified.
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :organization, touch: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should belong_to(:organization).touch(true) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should belong_to(:organization).touch(true)
      #     end
      #
      # ##### autosave
      #
      # Use `autosave` to assert that the `:autosave` option was specified.
      #
      #     class Account < ActiveRecord::Base
      #       belongs_to :bank, autosave: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Account, type: :model do
      #       it { should belong_to(:bank).autosave(true) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class AccountTest < ActiveSupport::TestCase
      #       should belong_to(:bank).autosave(true)
      #     end
      #
      # ##### inverse_of
      #
      # Use `inverse_of` to assert that the `:inverse_of` option was specified.
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :organization, inverse_of: :employees
      #     end
      #
      #     # RSpec
      #     describe Person
      #       it { should belong_to(:organization).inverse_of(:employees) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should belong_to(:organization).inverse_of(:employees)
      #     end
      #
      # ##### required
      #
      # Use `required` to assert that the association is not allowed to be nil.
      # (Enabled by default in Rails 5+.)
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :organization, required: true
      #     end
      #
      #     # RSpec
      #     describe Person
      #       it { should belong_to(:organization).required }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should belong_to(:organization).required
      #     end
      #
      # ##### without_validating_presence
      #
      # Use `without_validating_presence` with `belong_to` to prevent the
      # matcher from checking whether the association disallows nil (Rails 5+
      # only). This can be helpful if you have a custom hook that always sets
      # the association to a meaningful value:
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :organization
      #
      #       before_validation :autoassign_organization
      #
      #       private
      #
      #       def autoassign_organization
      #         self.organization = Organization.create!
      #       end
      #     end
      #
      #     # RSpec
      #     describe Person
      #       it { should belong_to(:organization).without_validating_presence }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should belong_to(:organization).without_validating_presence
      #     end
      #
      # ##### optional
      #
      # Use `optional` to assert that the association is allowed to be nil.
      # (Rails 5+ only.)
      #
      #     class Person < ActiveRecord::Base
      #       belongs_to :organization, optional: true
      #     end
      #
      #     # RSpec
      #     describe Person
      #       it { should belong_to(:organization).optional }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should belong_to(:organization).optional
      #     end
      #
      # @return [AssociationMatcher]
      #
      def belong_to(name)
        AssociationMatcher.new(:belongs_to, name)
      end

      # The `have_many` matcher is used to test that a `has_many` or `has_many
      # :through` association exists on your model.
      #
      #     class Person < ActiveRecord::Base
      #       has_many :friends
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_many(:friends) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_many(:friends)
      #     end
      #
      # Note that polymorphic associations are automatically detected and do not
      # need any qualifiers:
      #
      #     class Person < ActiveRecord::Base
      #       has_many :pictures, as: :imageable
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_many(:pictures) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_many(:pictures)
      #     end
      #
      # #### Qualifiers
      #
      # ##### conditions
      #
      # Use `conditions` if your association is defined with a scope that sets
      # the `where` clause.
      #
      #     class Person < ActiveRecord::Base
      #       has_many :coins, -> { where(quality: 'mint') }
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_many(:coins).conditions(quality: 'mint') }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_many(:coins).conditions(quality: 'mint')
      #     end
      #
      # ##### order
      #
      # Use `order` if your association is defined with a scope that sets the
      # `order` clause.
      #
      #     class Person < ActiveRecord::Base
      #       has_many :shirts, -> { order('color') }
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_many(:shirts).order('color') }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_many(:shirts).order('color')
      #     end
      #
      # ##### class_name
      #
      # Use `class_name` to test usage of the `:class_name` option. This
      # asserts that the model you're referring to actually exists.
      #
      #     class Person < ActiveRecord::Base
      #       has_many :hopes, class_name: 'Dream'
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_many(:hopes).class_name('Dream') }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_many(:hopes).class_name('Dream')
      #     end
      #
      # ##### with_primary_key
      #
      # Use `with_primary_key` to test usage of the `:primary_key` option.
      #
      #     class Person < ActiveRecord::Base
      #       has_many :worries, primary_key: 'worrier_id'
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_many(:worries).with_primary_key('worrier_id') }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_many(:worries).with_primary_key('worrier_id')
      #     end
      #
      # ##### with_foreign_key
      #
      # Use `with_foreign_key` to test usage of the `:foreign_key` option.
      #
      #     class Person < ActiveRecord::Base
      #       has_many :worries, foreign_key: 'worrier_id'
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_many(:worries).with_foreign_key('worrier_id') }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_many(:worries).with_foreign_key('worrier_id')
      #     end
      #
      # ##### dependent
      #
      # Use `dependent` to assert that the `:dependent` option was specified.
      #
      #     class Person < ActiveRecord::Base
      #       has_many :secret_documents, dependent: :destroy
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_many(:secret_documents).dependent(:destroy) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_many(:secret_documents).dependent(:destroy)
      #     end
      #
      # ##### through
      #
      # Use `through` to test usage of the `:through` option. This asserts that
      # the association you are going through actually exists.
      #
      #     class Person < ActiveRecord::Base
      #       has_many :acquaintances, through: :friends
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_many(:acquaintances).through(:friends) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_many(:acquaintances).through(:friends)
      #     end
      #
      # ##### source
      #
      # Use `source` to test usage of the `:source` option on a `:through`
      # association.
      #
      #     class Person < ActiveRecord::Base
      #       has_many :job_offers, through: :friends, source: :opportunities
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should have_many(:job_offers).
      #           through(:friends).
      #           source(:opportunities)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_many(:job_offers).
      #         through(:friends).
      #         source(:opportunities)
      #     end
      #
      # ##### validate
      #
      # Use `validate` to assert that the `:validate` option was specified.
      #
      #     class Person < ActiveRecord::Base
      #       has_many :ideas, validate: false
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_many(:ideas).validate(false) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_many(:ideas).validate(false)
      #     end
      #
      # ##### autosave
      #
      # Use `autosave` to assert that the `:autosave` option was specified.
      #
      #     class Player < ActiveRecord::Base
      #       has_many :games, autosave: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Player, type: :model do
      #       it { should have_many(:games).autosave(true) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PlayerTest < ActiveSupport::TestCase
      #       should have_many(:games).autosave(true)
      #     end
      #
      # ##### index_errors
      #
      # Use `index_errors` to assert that the `:index_errors` option was
      # specified.
      #
      #     class Player < ActiveRecord::Base
      #       has_many :games, index_errors: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Player, type: :model do
      #       it { should have_many(:games).index_errors(true) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PlayerTest < ActiveSupport::TestCase
      #       should have_many(:games).index_errors(true)
      #     end
      #
      # ##### inverse_of
      #
      # Use `inverse_of` to assert that the `:inverse_of` option was specified.
      #
      #     class Organization < ActiveRecord::Base
      #       has_many :employees, inverse_of: :company
      #     end
      #
      #     # RSpec
      #     describe Organization
      #       it { should have_many(:employees).inverse_of(:company) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class OrganizationTest < ActiveSupport::TestCase
      #       should have_many(:employees).inverse_of(:company)
      #     end
      #
      # @return [AssociationMatcher]
      #
      def have_many(name)
        AssociationMatcher.new(:has_many, name)
      end

      # The `have_one` matcher is used to test that a `has_one` or `has_one
      # :through` association exists on your model.
      #
      #     class Person < ActiveRecord::Base
      #       has_one :partner
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_one(:partner) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_one(:partner)
      #     end
      #
      # #### Qualifiers
      #
      # ##### conditions
      #
      # Use `conditions` if your association is defined with a scope that sets
      # the `where` clause.
      #
      #     class Person < ActiveRecord::Base
      #       has_one :pet, -> { where('weight < 80') }
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_one(:pet).conditions('weight < 80') }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_one(:pet).conditions('weight < 80')
      #     end
      #
      # ##### order
      #
      # Use `order` if your association is defined with a scope that sets the
      # `order` clause.
      #
      #     class Person < ActiveRecord::Base
      #       has_one :focus, -> { order('priority desc') }
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_one(:focus).order('priority desc') }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_one(:focus).order('priority desc')
      #     end
      #
      # ##### class_name
      #
      # Use `class_name` to test usage of the `:class_name` option. This
      # asserts that the model you're referring to actually exists.
      #
      #     class Person < ActiveRecord::Base
      #       has_one :chance, class_name: 'Opportunity'
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_one(:chance).class_name('Opportunity') }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_one(:chance).class_name('Opportunity')
      #     end
      #
      # ##### dependent
      #
      # Use `dependent` to test that the `:dependent` option was specified.
      #
      #     class Person < ActiveRecord::Base
      #       has_one :contract, dependent: :nullify
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_one(:contract).dependent(:nullify) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_one(:contract).dependent(:nullify)
      #     end
      #
      # ##### with_primary_key
      #
      # Use `with_primary_key` to test usage of the `:primary_key` option.
      #
      #     class Person < ActiveRecord::Base
      #       has_one :job, primary_key: 'worker_id'
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_one(:job).with_primary_key('worker_id') }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_one(:job).with_primary_key('worker_id')
      #     end
      #
      # ##### with_foreign_key
      #
      # Use `with_foreign_key` to test usage of the `:foreign_key` option.
      #
      #     class Person < ActiveRecord::Base
      #       has_one :job, foreign_key: 'worker_id'
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_one(:job).with_foreign_key('worker_id') }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_one(:job).with_foreign_key('worker_id')
      #     end
      #
      # ##### through
      #
      # Use `through` to test usage of the `:through` option. This asserts that
      # the association you are going through actually exists.
      #
      #     class Person < ActiveRecord::Base
      #       has_one :life, through: :partner
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_one(:life).through(:partner) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_one(:life).through(:partner)
      #     end
      #
      # ##### source
      #
      # Use `source` to test usage of the `:source` option on a `:through`
      # association.
      #
      #     class Person < ActiveRecord::Base
      #       has_one :car, through: :partner, source: :vehicle
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_one(:car).through(:partner).source(:vehicle) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_one(:car).through(:partner).source(:vehicle)
      #     end
      #
      # ##### validate
      #
      # Use `validate` to assert that the the `:validate` option was specified.
      #
      #     class Person < ActiveRecord::Base
      #       has_one :parking_card, validate: false
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_one(:parking_card).validate(false) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_one(:parking_card).validate(false)
      #     end
      #
      # ##### autosave
      #
      # Use `autosave` to assert that the `:autosave` option was specified.
      #
      #     class Account < ActiveRecord::Base
      #       has_one :bank, autosave: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Account, type: :model do
      #       it { should have_one(:bank).autosave(true) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class AccountTest < ActiveSupport::TestCase
      #       should have_one(:bank).autosave(true)
      #     end
      #
      # ##### required
      #
      # Use `required` to assert that the association is not allowed to be nil.
      # (Rails 5+ only.)
      #
      #     class Person < ActiveRecord::Base
      #       has_one :brain, required: true
      #     end
      #
      #     # RSpec
      #     describe Person
      #       it { should have_one(:brain).required }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_one(:brain).required
      #     end
      #
      # @return [AssociationMatcher]
      #
      def have_one(name)
        AssociationMatcher.new(:has_one, name)
      end

      # The `have_and_belong_to_many` matcher is used to test that a
      # `has_and_belongs_to_many` association exists on your model and that the
      # join table exists in the database.
      #
      #     class Person < ActiveRecord::Base
      #       has_and_belongs_to_many :awards
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it { should have_and_belong_to_many(:awards) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_and_belong_to_many(:awards)
      #     end
      #
      # #### Qualifiers
      #
      # ##### conditions
      #
      # Use `conditions` if your association is defined with a scope that sets
      # the `where` clause.
      #
      #     class Person < ActiveRecord::Base
      #       has_and_belongs_to_many :issues, -> { where(difficulty: 'hard') }
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should have_and_belong_to_many(:issues).
      #           conditions(difficulty: 'hard')
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_and_belong_to_many(:issues).
      #         conditions(difficulty: 'hard')
      #     end
      #
      # ##### order
      #
      # Use `order` if your association is defined with a scope that sets the
      # `order` clause.
      #
      #     class Person < ActiveRecord::Base
      #       has_and_belongs_to_many :projects, -> { order('time_spent') }
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should have_and_belong_to_many(:projects).
      #           order('time_spent')
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_and_belong_to_many(:projects).
      #         order('time_spent')
      #     end
      #
      # ##### class_name
      #
      # Use `class_name` to test usage of the `:class_name` option. This
      # asserts that the model you're referring to actually exists.
      #
      #     class Person < ActiveRecord::Base
      #       has_and_belongs_to_many :places_visited, class_name: 'City'
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should have_and_belong_to_many(:places_visited).
      #           class_name('City')
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_and_belong_to_many(:places_visited).
      #         class_name('City')
      #     end
      #
      # ##### join_table
      #
      # Use `join_table` to test usage of the `:join_table` option. This
      # asserts that the table you're referring to actually exists.
      #
      #     class Person < ActiveRecord::Base
      #       has_and_belongs_to_many :issues, join_table: :people_tickets
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should have_and_belong_to_many(:issues).
      #           join_table(:people_tickets)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_and_belong_to_many(:issues).
      #         join_table(:people_tickets)
      #     end
      #
      # ##### validate
      #
      # Use `validate` to test that the `:validate` option was specified.
      #
      #     class Person < ActiveRecord::Base
      #       has_and_belongs_to_many :interviews, validate: false
      #     end
      #
      #     # RSpec
      #     RSpec.describe Person, type: :model do
      #       it do
      #         should have_and_belong_to_many(:interviews).
      #           validate(false)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PersonTest < ActiveSupport::TestCase
      #       should have_and_belong_to_many(:interviews).
      #         validate(false)
      #     end
      #
      # ##### autosave
      #
      # Use `autosave` to assert that the `:autosave` option was specified.
      #
      #     class Publisher < ActiveRecord::Base
      #       has_and_belongs_to_many :advertisers, autosave: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Publisher, type: :model do
      #       it { should have_and_belong_to_many(:advertisers).autosave(true) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class AccountTest < ActiveSupport::TestCase
      #       should have_and_belong_to_many(:advertisers).autosave(true)
      #     end
      #
      # @return [AssociationMatcher]
      #
      def have_and_belong_to_many(name)
        AssociationMatcher.new(:has_and_belongs_to_many, name)
      end

      # @private
      class AssociationMatcher
        MACROS = {
          'belongs_to' => 'belong to',
          'has_many' => 'have many',
          'has_one' => 'have one',
          'has_and_belongs_to_many' => 'have and belong to many',
        }.freeze

        delegate :reflection, :model_class, :associated_class, :through?,
          :polymorphic?, to: :reflector

        attr_reader :name, :options

        def initialize(macro, name)
          @macro = macro
          @name = name
          @options = {}
          @submatchers = []
          @missing = ''

          if macro == :belongs_to
            required(belongs_to_required_by_default?)
          end
        end

        def through(through)
          add_submatcher(
            AssociationMatchers::ThroughMatcher,
            through,
            name,
          )
          self
        end

        def dependent(dependent)
          add_submatcher(
            AssociationMatchers::DependentMatcher,
            dependent,
            name,
          )
          self
        end

        def order(order)
          add_submatcher(
            AssociationMatchers::OrderMatcher,
            order,
            name,
          )
          self
        end

        def counter_cache(counter_cache = true)
          add_submatcher(
            AssociationMatchers::CounterCacheMatcher,
            counter_cache,
            name,
          )
          self
        end

        def inverse_of(inverse_of)
          add_submatcher(
            AssociationMatchers::InverseOfMatcher,
            inverse_of,
            name,
          )
          self
        end

        def source(source)
          add_submatcher(
            AssociationMatchers::SourceMatcher,
            source,
            name,
          )
          self
        end

        def conditions(conditions)
          @options[:conditions] = conditions
          self
        end

        def autosave(autosave)
          @options[:autosave] = autosave
          self
        end

        def index_errors(index_errors)
          @options[:index_errors] = index_errors
          self
        end

        def class_name(class_name)
          @options[:class_name] = class_name
          self
        end

        def with_foreign_key(foreign_key)
          @options[:foreign_key] = foreign_key
          self
        end

        def with_primary_key(primary_key)
          @options[:primary_key] = primary_key
          self
        end

        def required(required = true)
          remove_submatcher(AssociationMatchers::OptionalMatcher)
          add_submatcher(
            AssociationMatchers::RequiredMatcher,
            name,
            required,
          )
          self
        end

        def optional(optional = true)
          remove_submatcher(AssociationMatchers::RequiredMatcher)
          add_submatcher(
            AssociationMatchers::OptionalMatcher,
            name,
            optional,
          )
          self
        end

        def validate(validate = true)
          @options[:validate] = validate
          self
        end

        def touch(touch = true)
          @options[:touch] = touch
          self
        end

        def join_table(join_table_name)
          @options[:join_table_name] = join_table_name
          self
        end

        def without_validating_presence
          remove_submatcher(AssociationMatchers::RequiredMatcher)
          self
        end

        def description
          description = "#{macro_description} #{name}"
          if options.key?(:class_name)
            description += " class_name => #{options[:class_name]}"
          end
          [description, submatchers.map(&:description)].flatten.join(' ')
        end

        def failure_message
          "Expected #{expectation} (#{missing_options})"
        end

        def failure_message_when_negated
          "Did not expect #{expectation}"
        end

        def matches?(subject)
          @subject = subject
          association_exists? &&
            macro_correct? &&
            validate_inverse_of_through_association &&
            (polymorphic? || class_exists?) &&
            foreign_key_exists? &&
            primary_key_exists? &&
            class_name_correct? &&
            join_table_correct? &&
            autosave_correct? &&
            index_errors_correct? &&
            conditions_correct? &&
            validate_correct? &&
            touch_correct? &&
            submatchers_match?
        end

        def join_table_name
          options[:join_table_name] || reflector.join_table_name
        end

        def option_verifier
          @_option_verifier ||=
            AssociationMatchers::OptionVerifier.new(reflector)
        end

        protected

        attr_reader :submatchers, :missing, :subject, :macro

        def reflector
          @_reflector ||= AssociationMatchers::ModelReflector.new(subject, name)
        end

        def add_submatcher(matcher_class, *args)
          remove_submatcher(matcher_class)
          submatchers << matcher_class.new(*args)
        end

        def remove_submatcher(matcher_class)
          submatchers.delete_if do |submatcher|
            submatcher.is_a?(matcher_class)
          end
        end

        def macro_description
          MACROS[macro.to_s]
        end

        def expectation
          expectation =
            "#{model_class.name} to have a #{macro} association called #{name}"

          if through?
            expectation << " through #{reflector.has_and_belongs_to_many_name}"
          end

          expectation
        end

        def missing_options
          missing_options = [missing, missing_options_for_failing_submatchers]
          missing_options.flatten.select(&:present?).join(', ')
        end

        def failing_submatchers
          @_failing_submatchers ||= submatchers.reject do |matcher|
            matcher.matches?(subject)
          end
        end

        def missing_options_for_failing_submatchers
          if defined?(@_failing_submatchers)
            @_failing_submatchers.map(&:missing_option)
          else
            []
          end
        end

        def association_exists?
          if reflection.nil?
            @missing = "no association called #{name}"
            false
          else
            true
          end
        end

        def macro_correct?
          if reflection.macro == macro
            true
          elsif reflection.macro == :has_many
            macro == :has_and_belongs_to_many &&
              reflection.name == @name
          else
            @missing = "actual association type was #{reflection.macro}"
            false
          end
        end

        def validate_inverse_of_through_association
          reflector.validate_inverse_of_through_association!
          true
        rescue ::ActiveRecord::ActiveRecordError => e
          @missing = e.message
          false
        end

        def macro_supports_primary_key?
          macro == :belongs_to ||
            ([:has_many, :has_one].include?(macro) && !through?)
        end

        def foreign_key_exists?
          !(belongs_foreign_key_missing? || has_foreign_key_missing?)
        end

        def primary_key_exists?
          !macro_supports_primary_key? || primary_key_correct?(model_class)
        end

        def belongs_foreign_key_missing?
          macro == :belongs_to && !class_has_foreign_key?(model_class)
        end

        def has_foreign_key_missing?
          [:has_many, :has_one].include?(macro) &&
            !through? &&
            !class_has_foreign_key?(associated_class)
        end

        def class_name_correct?
          if options.key?(:class_name)
            if option_verifier.correct_for_constant?(
              :class_name,
              options[:class_name],
            )
              true
            else
              @missing = "#{name} should resolve to #{options[:class_name]}"\
                ' for class_name'
              false
            end
          else
            true
          end
        end

        def join_table_correct?
          if (
            macro != :has_and_belongs_to_many ||
            join_table_matcher.matches?(@subject)
          )
            true
          else
            @missing = join_table_matcher.failure_message
            false
          end
        end

        def join_table_matcher
          @_join_table_matcher ||= AssociationMatchers::JoinTableMatcher.new(
            self,
            reflector,
          )
        end

        def class_exists?
          associated_class
          true
        rescue NameError
          @missing = "#{reflection.class_name} does not exist"
          false
        end

        def autosave_correct?
          if options.key?(:autosave)
            if option_verifier.correct_for_boolean?(
              :autosave,
              options[:autosave],
            )
              true
            else
              @missing = "#{name} should have autosave set to"\
                " #{options[:autosave]}"
              false
            end
          else
            true
          end
        end

        def index_errors_correct?
          return true unless options.key?(:index_errors)

          if option_verifier.correct_for_boolean?(
            :index_errors,
            options[:index_errors],
          )
            true
          else
            @missing =
              "#{name} should have index_errors set to " +
              options[:index_errors].to_s
            false
          end
        end

        def conditions_correct?
          if options.key?(:conditions)
            if option_verifier.correct_for_relation_clause?(
              :conditions,
              options[:conditions],
            )
              true
            else
              @missing = "#{name} should have the following conditions:" +
                         " #{options[:conditions]}"
              false
            end
          else
            true
          end
        end

        def validate_correct?
          if option_verifier.correct_for_boolean?(:validate, options[:validate])
            true
          else
            @missing = "#{name} should have validate: #{options[:validate]}"
            false
          end
        end

        def touch_correct?
          if option_verifier.correct_for_boolean?(:touch, options[:touch])
            true
          else
            @missing = "#{name} should have touch: #{options[:touch]}"
            false
          end
        end

        def class_has_foreign_key?(klass)
          @missing = validate_foreign_key(klass)

          @missing.nil?
        end

        def validate_foreign_key(klass)
          if options.key?(:foreign_key) && !foreign_key_correct?
            foreign_key_failure_message(klass, options[:foreign_key])
          elsif !has_column?(klass, actual_foreign_key)
            foreign_key_failure_message(klass, actual_foreign_key)
          end
        end

        def has_column?(klass, column)
          case column
          when Array
            column.all? { |c| has_column?(klass, c.to_s) }
          else
            column_names_for(klass).include?(column.to_s)
          end
        end

        def foreign_key_correct?
          option_verifier.correct_for_string?(
            :foreign_key,
            options[:foreign_key],
          )
        end

        def foreign_key_failure_message(klass, foreign_key)
          "#{klass} does not have a #{foreign_key} foreign key."
        end

        def primary_key_correct?(klass)
          if options.key?(:primary_key)
            if option_verifier.correct_for_string?(
              :primary_key,
              options[:primary_key],
            )
              true
            else
              @missing = "#{klass} does not have a #{options[:primary_key]}"\
                ' primary key'
              false
            end
          else
            true
          end
        end

        def actual_foreign_key
          return unless foreign_key_reflection

          if foreign_key_reflection.options[:foreign_key]
            foreign_key_reflection.options[:foreign_key]
          elsif foreign_key_reflection.respond_to?(:foreign_key)
            foreign_key_reflection.foreign_key
          else
            foreign_key_reflection.primary_key_name
          end
        end

        def foreign_key_reflection
          if (
            [:has_one, :has_many].include?(macro) &&
            reflection.options.include?(:inverse_of) &&
            reflection.options[:inverse_of] != false
          )
            associated_class.reflect_on_association(
              reflection.options[:inverse_of],
            )
          else
            reflection
          end
        end

        def submatchers_match?
          failing_submatchers.empty?
        end

        def column_names_for(klass)
          klass.column_names
        rescue ::ActiveRecord::StatementInvalid
          []
        end

        def belongs_to_required_by_default?
          ::ActiveRecord::Base.belongs_to_required_by_default
        end
      end
    end
  end
end
