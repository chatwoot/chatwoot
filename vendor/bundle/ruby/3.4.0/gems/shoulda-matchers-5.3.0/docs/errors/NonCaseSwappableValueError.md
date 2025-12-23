# @title NonCaseSwappableValueError

# NonCaseSwappableValueError

This error is raised when using `validate_uniqueness_of`. This matcher, of
course, tests that an attribute disallows a non-unique value -- and what
constitutes as "unique" depends on whether the case-sensitivity of that value
matters. If it does matter -- meaning that the uniqueness validation in your
model isn't using `case_sensitive: false` and you haven't qualified the matcher
with `case_insensitive` -- then the matcher will run the following test:

> Creating first a record with a value of "A":
>
> * A new record with a value of "A" should not be valid (failing the uniqueness
>   validation)
> * A new record with a value of "a" should be valid

The test value we're using is in this case "A", and this is what the matcher
will use if an existing record is not already present in the database. But if
a record already exists, then the matcher will use it as comparison -- it will
read the attribute under test off of the record and use its value. So a better
example might be:

> Given an existing record with a value:
>
> * A new record with the same value should not be valid (failing the uniqueness
>   validation)
> * A new record with the same value, but where the case is swapped (using
>   String#swapcase), should be valid

Now, what happens if an existing record is there, but the value being used is
not one whose case can be swapped, such as `"123"` or `"{-#%}"`? Then the second
assertion cannot be made effectively.

So this is why you're getting this exception. What can you do about it? As the
error message explains, you have two options:

1. If you want the uniqueness validation in the model to operate
   case-sensitively and you didn't mean to use a non-case-swappable value,
   then you need to provide an existing record with a different value, one that
   contains alpha characters. Here's an example:

        # Model
        class User < ActiveRecord::Base
          validates_uniqueness_of :username
        end

        # RSpec
        RSpec.describe User, type: :model do
          context "validations" do
            subject do
              # Note that "123" == "123".swapcase. This is a problem!
              User.new(username: "123")
            end

            it do
              # So you can either override it like this, or just fix the subject.
              user = User.create!(username: "john123")
              expect(user).to validate_uniqueness_of(:username)
            end
          end
        end

        # Minitest (Shoulda)
        class UserTest < ActiveSupport::TestCase
          context "validations" do
            subject do
              # Note that "123" == "123".swapcase. This is a problem!
              User.new(username: "123")
            end

            should "validate uniqueness of :username" do
              # So you can either override it like this, or just fix the subject.
              user = User.create!(username: "john123")
              assert_accepts validate_uniqueness_of(:username), record
            end
          end
        end

2. If you don't want the uniqueness validation to operate case-sensitively,
   then you need to add `case_sensitive: false` to the validation and add
   `case_insensitive` to the matcher:

        # Model
        class User < ActiveRecord::Base
          validates_uniqueness_of :username, case_sensitive: false
        end
        
        # RSpec
        RSpec.describe User, type: :model do
          context "validations" do
            subject do
              # Note that "123" == "123".swapcase, but it's okay
              User.new(username: "123")
            end

            it { should validate_uniqueness_of(:username).case_insensitive }
          end
        end
        
        # Minitest (Shoulda)
        class UserTest < ActiveSupport::TestCase
          context "validations" do
            subject do
              # Note that "123" == "123".swapcase, but it's okay
              User.new(username: "123")
            end

            should validate_uniqueness_of(:username).case_insensitive
          end
        end
