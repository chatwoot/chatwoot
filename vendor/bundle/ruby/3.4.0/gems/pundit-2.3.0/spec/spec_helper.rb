# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "pundit"
require "pundit/rspec"

require "rack"
require "rack/test"
require "pry"
require "active_support"
require "active_support/core_ext"
require "active_model/naming"
require "action_controller/metal/strong_parameters"

class PostPolicy < Struct.new(:user, :post)
  class Scope < Struct.new(:user, :scope)
    def resolve
      scope.published
    end
  end

  def update?
    post.user == user
  end

  def destroy?
    false
  end

  def show?
    true
  end

  def permitted_attributes
    if post.user == user
      %i[title votes]
    else
      [:votes]
    end
  end

  def permitted_attributes_for_revise
    [:body]
  end
end

class Post < Struct.new(:user)
  def self.published
    :published
  end

  def self.read
    :read
  end

  def to_s
    "Post"
  end

  def inspect
    "#<Post>"
  end
end

module Customer
  class Post < Post
    def model_name
      OpenStruct.new(param_key: "customer_post")
    end

    def self.policy_class
      PostPolicy
    end
  end
end

class CommentScope
  attr_reader :original_object

  def initialize(original_object)
    @original_object = original_object
  end

  def ==(other)
    original_object == other.original_object
  end
end

class CommentPolicy < Struct.new(:user, :comment)
  class Scope < Struct.new(:user, :scope)
    def resolve
      CommentScope.new(scope)
    end
  end
end

class PublicationPolicy < Struct.new(:user, :publication)
  class Scope < Struct.new(:user, :scope)
    def resolve
      scope.published
    end
  end

  def create?
    true
  end
end

class Comment
  extend ActiveModel::Naming
end

class CommentsRelation
  def initialize(empty: false)
    @empty = empty
  end

  def blank?
    @empty
  end

  def self.model_name
    Comment.model_name
  end
end

class Article; end

class BlogPolicy < Struct.new(:user, :blog); end

class Blog; end

class ArtificialBlog < Blog
  def self.policy_class
    BlogPolicy
  end
end

class ArticleTagOtherNamePolicy < Struct.new(:user, :tag)
  def show?
    true
  end

  def destroy?
    false
  end
end

class ArticleTag
  def self.policy_class
    ArticleTagOtherNamePolicy
  end
end

class CriteriaPolicy < Struct.new(:user, :criteria); end

module Project
  class CommentPolicy < Struct.new(:user, :comment)
    def update?
      true
    end

    class Scope < Struct.new(:user, :scope)
      def resolve
        scope
      end
    end
  end

  class CriteriaPolicy < Struct.new(:user, :criteria); end

  class PostPolicy < Struct.new(:user, :post)
    class Scope < Struct.new(:user, :scope)
      def resolve
        scope.read
      end
    end
  end

  module Admin
    class CommentPolicy < Struct.new(:user, :comment)
      def update?
        true
      end

      def destroy?
        false
      end
    end
  end
end

class DenierPolicy < Struct.new(:user, :record)
  def update?
    false
  end
end

class Controller
  include Pundit::Authorization
  # Mark protected methods public so they may be called in test
  # rubocop:disable Style/AccessModifierDeclarations
  public(*Pundit::Authorization.protected_instance_methods)
  # rubocop:enable Style/AccessModifierDeclarations

  attr_reader :current_user, :action_name, :params

  def initialize(current_user, action_name, params)
    @current_user = current_user
    @action_name = action_name
    @params = params
  end
end

class NilClassPolicy < Struct.new(:user, :record)
  class Scope
    def initialize(*)
      raise Pundit::NotDefinedError, "Cannot scope NilClass"
    end
  end

  def show?
    false
  end

  def destroy?
    false
  end
end

class Wiki; end

class WikiPolicy
  class Scope
    # deliberate typo method
    def initalize; end
  end
end

class Thread
  def self.all; end
end

class ThreadPolicy < Struct.new(:user, :thread)
  class Scope < Struct.new(:user, :scope)
    def resolve
      # deliberate wrong useage of the method
      scope.all(:unvalid, :parameters)
    end
  end
end

class PostFourFiveSix < Struct.new(:user); end

class CommentFourFiveSix; extend ActiveModel::Naming; end

module ProjectOneTwoThree
  class CommentFourFiveSixPolicy < Struct.new(:user, :post); end

  class CriteriaFourFiveSixPolicy < Struct.new(:user, :criteria); end

  class PostFourFiveSixPolicy < Struct.new(:user, :post); end

  class TagFourFiveSix < Struct.new(:user); end

  class TagFourFiveSixPolicy < Struct.new(:user, :tag); end

  class AvatarFourFiveSix; extend ActiveModel::Naming; end

  class AvatarFourFiveSixPolicy < Struct.new(:user, :avatar); end
end
