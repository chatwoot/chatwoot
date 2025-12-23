# frozen_string_literal: true

require "spec_helper"

describe Pundit::Authorization do
  let(:controller) { Controller.new(user, "update", {}) }
  let(:user) { double }
  let(:post) { Post.new(user) }
  let(:customer_post) { Customer::Post.new(user) }
  let(:comment) { Comment.new }
  let(:article) { Article.new }
  let(:article_tag) { ArticleTag.new }
  let(:wiki) { Wiki.new }

  describe "#verify_authorized" do
    it "does nothing when authorized" do
      controller.authorize(post)
      controller.verify_authorized
    end

    it "raises an exception when not authorized" do
      expect { controller.verify_authorized }.to raise_error(Pundit::AuthorizationNotPerformedError)
    end
  end

  describe "#verify_policy_scoped" do
    it "does nothing when policy_scope is used" do
      controller.policy_scope(Post)
      controller.verify_policy_scoped
    end

    it "raises an exception when policy_scope is not used" do
      expect { controller.verify_policy_scoped }.to raise_error(Pundit::PolicyScopingNotPerformedError)
    end
  end

  describe "#pundit_policy_authorized?" do
    it "is true when authorized" do
      controller.authorize(post)
      expect(controller.pundit_policy_authorized?).to be true
    end

    it "is false when not authorized" do
      expect(controller.pundit_policy_authorized?).to be false
    end
  end

  describe "#pundit_policy_scoped?" do
    it "is true when policy_scope is used" do
      controller.policy_scope(Post)
      expect(controller.pundit_policy_scoped?).to be true
    end

    it "is false when policy scope is not used" do
      expect(controller.pundit_policy_scoped?).to be false
    end
  end

  describe "#authorize" do
    it "infers the policy name and authorizes based on it" do
      expect(controller.authorize(post)).to be_truthy
    end

    it "returns the record on successful authorization" do
      expect(controller.authorize(post)).to eq(post)
    end

    it "returns the record when passed record with namespace " do
      expect(controller.authorize([:project, comment], :update?)).to eq(comment)
    end

    it "returns the record when passed record with nested namespace " do
      expect(controller.authorize([:project, :admin, comment], :update?)).to eq(comment)
    end

    it "returns the policy name symbol when passed record with headless policy" do
      expect(controller.authorize(:publication, :create?)).to eq(:publication)
    end

    it "returns the class when passed record not a particular instance" do
      expect(controller.authorize(Post, :show?)).to eq(Post)
    end

    it "can be given a different permission to check" do
      expect(controller.authorize(post, :show?)).to be_truthy
      expect { controller.authorize(post, :destroy?) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "can be given a different policy class" do
      expect(controller.authorize(post, :create?, policy_class: PublicationPolicy)).to be_truthy
    end

    it "works with anonymous class policies" do
      expect(controller.authorize(article_tag, :show?)).to be_truthy
      expect { controller.authorize(article_tag, :destroy?) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "throws an exception when the permission check fails" do
      expect { controller.authorize(Post.new) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "throws an exception when a policy cannot be found" do
      expect { controller.authorize(Article) }.to raise_error(Pundit::NotDefinedError)
    end

    it "caches the policy" do
      expect(controller.policies[post]).to be_nil
      controller.authorize(post)
      expect(controller.policies[post]).not_to be_nil
    end

    it "raises an error when the given record is nil" do
      expect { controller.authorize(nil, :destroy?) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "raises an error with a invalid policy constructor" do
      expect { controller.authorize(wiki, :destroy?) }.to raise_error(Pundit::InvalidConstructorError)
    end
  end

  describe "#skip_authorization" do
    it "disables authorization verification" do
      controller.skip_authorization
      expect { controller.verify_authorized }.not_to raise_error
    end
  end

  describe "#skip_policy_scope" do
    it "disables policy scope verification" do
      controller.skip_policy_scope
      expect { controller.verify_policy_scoped }.not_to raise_error
    end
  end

  describe "#pundit_user" do
    it "returns the same thing as current_user" do
      expect(controller.pundit_user).to eq controller.current_user
    end
  end

  describe "#policy" do
    it "returns an instantiated policy" do
      policy = controller.policy(post)
      expect(policy.user).to eq user
      expect(policy.post).to eq post
    end

    it "throws an exception if the given policy can't be found" do
      expect { controller.policy(article) }.to raise_error(Pundit::NotDefinedError)
    end

    it "raises an error with a invalid policy constructor" do
      expect { controller.policy(wiki) }.to raise_error(Pundit::InvalidConstructorError)
    end

    it "allows policy to be injected" do
      new_policy = OpenStruct.new
      controller.policies[post] = new_policy

      expect(controller.policy(post)).to eq new_policy
    end
  end

  describe "#policy_scope" do
    it "returns an instantiated policy scope" do
      expect(controller.policy_scope(Post)).to eq :published
    end

    it "allows policy scope class to be overriden" do
      expect(controller.policy_scope(Post, policy_scope_class: PublicationPolicy::Scope)).to eq :published
    end

    it "throws an exception if the given policy can't be found" do
      expect { controller.policy_scope(Article) }.to raise_error(Pundit::NotDefinedError)
    end

    it "raises an error with a invalid policy scope constructor" do
      expect { controller.policy_scope(Wiki) }.to raise_error(Pundit::InvalidConstructorError)
    end

    it "allows policy_scope to be injected" do
      new_scope = OpenStruct.new
      controller.policy_scopes[Post] = new_scope

      expect(controller.policy_scope(Post)).to eq new_scope
    end
  end

  describe "#permitted_attributes" do
    it "checks policy for permitted attributes" do
      params = ActionController::Parameters.new(
        post: {
          title: "Hello",
          votes: 5,
          admin: true
        }
      )

      action = "update"

      expect(Controller.new(user, action, params).permitted_attributes(post).to_h).to eq(
        "title" => "Hello",
        "votes" => 5
      )
      expect(Controller.new(double, action, params).permitted_attributes(post).to_h).to eq("votes" => 5)
    end

    it "checks policy for permitted attributes for record of a ActiveModel type" do
      params = ActionController::Parameters.new(
        customer_post: {
          title: "Hello",
          votes: 5,
          admin: true
        }
      )

      action = "update"

      expect(Controller.new(user, action, params).permitted_attributes(customer_post).to_h).to eq(
        "title" => "Hello",
        "votes" => 5
      )
      expect(Controller.new(double, action, params).permitted_attributes(customer_post).to_h).to eq(
        "votes" => 5
      )
    end
  end

  describe "#permitted_attributes_for_action" do
    it "is checked if it is defined in the policy" do
      params = ActionController::Parameters.new(
        post: {
          title: "Hello",
          body: "blah",
          votes: 5,
          admin: true
        }
      )

      action = "revise"
      expect(Controller.new(user, action, params).permitted_attributes(post).to_h).to eq("body" => "blah")
    end

    it "can be explicitly set" do
      params = ActionController::Parameters.new(
        post: {
          title: "Hello",
          body: "blah",
          votes: 5,
          admin: true
        }
      )

      action = "update"
      expect(Controller.new(user, action, params).permitted_attributes(post, :revise).to_h).to eq("body" => "blah")
    end
  end
end
