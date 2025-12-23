require "cgi"
require File.expand_path("../schema", __FILE__)

module Models
  module ActiveRecord
    class User < ::ActiveRecord::Base
      audited except: :password
      attribute :non_column_attr if Rails.version >= "5.1"
      attr_protected :logins if respond_to?(:attr_protected)
      enum status: {active: 0, reliable: 1, banned: 2}

      if Rails.version >= "7.1"
        serialize :phone_numbers, type: Array
      else
        serialize :phone_numbers, Array
      end

      def name=(val)
        write_attribute(:name, CGI.escapeHTML(val))
      end
    end

    class UserExceptPassword < ::ActiveRecord::Base
      self.table_name = :users
      audited except: :password
    end

    class UserOnlyPassword < ::ActiveRecord::Base
      self.table_name = :users
      attribute :non_column_attr if Rails.version >= "5.1"
      audited only: :password
    end

    class UserRedactedPassword < ::ActiveRecord::Base
      self.table_name = :users
      audited redacted: :password
    end

    class UserMultipleRedactedAttributes < ::ActiveRecord::Base
      self.table_name = :users
      audited redacted: [:password, :ssn]
    end

    class UserRedactedPasswordCustomRedaction < ::ActiveRecord::Base
      self.table_name = :users
      audited redacted: :password, redaction_value: ["My", "Custom", "Value", 7]
    end

    if ::ActiveRecord::VERSION::MAJOR >= 7
      class UserWithEncryptedPassword < ::ActiveRecord::Base
        self.table_name = :users
        audited
        encrypts :password
      end
    end

    class CommentRequiredUser < ::ActiveRecord::Base
      self.table_name = :users
      audited except: :password, comment_required: true
    end

    class OnCreateCommentRequiredUser < ::ActiveRecord::Base
      self.table_name = :users
      audited comment_required: true, on: :create
    end

    class OnUpdateCommentRequiredUser < ::ActiveRecord::Base
      self.table_name = :users
      audited comment_required: true, on: :update
    end

    class OnDestroyCommentRequiredUser < ::ActiveRecord::Base
      self.table_name = :users
      audited comment_required: true, on: :destroy
    end

    class NoUpdateWithCommentOnlyUser < ::ActiveRecord::Base
      self.table_name = :users
      audited update_with_comment_only: false
    end

    class AccessibleAfterDeclarationUser < ::ActiveRecord::Base
      self.table_name = :users
      audited
      attr_accessible :name, :username, :password if respond_to?(:attr_accessible)
    end

    class AccessibleBeforeDeclarationUser < ::ActiveRecord::Base
      self.table_name = :users
      attr_accessible :name, :username, :password if respond_to?(:attr_accessible) # declare attr_accessible before calling aaa
      audited
    end

    class NoAttributeProtectionUser < ::ActiveRecord::Base
      self.table_name = :users
      audited
    end

    class UserWithAfterAudit < ::ActiveRecord::Base
      self.table_name = :users
      audited
      attr_accessor :bogus_attr, :around_attr

      private

      def after_audit
        self.bogus_attr = "do something"
      end

      def around_audit
        self.around_attr = yield
      end
    end

    class MaxAuditsUser < ::ActiveRecord::Base
      self.table_name = :users
      audited max_audits: 5
    end

    class Company < ::ActiveRecord::Base
      audited
    end

    class Company::STICompany < Company
    end

    class Owner < ::ActiveRecord::Base
      self.table_name = "users"
      audited
      has_associated_audits
      has_many :companies, class_name: "OwnedCompany", dependent: :destroy
      accepts_nested_attributes_for :companies
    end

    class OwnedCompany < ::ActiveRecord::Base
      self.table_name = "companies"
      belongs_to :owner, class_name: "Owner", touch: true
      attr_accessible :name, :owner if respond_to?(:attr_accessible) # declare attr_accessible before calling aaa
      audited associated_with: :owner
    end

    class OwnedCompany::STICompany < OwnedCompany
    end

    class OnUpdateDestroy < ::ActiveRecord::Base
      self.table_name = "companies"
      audited on: [:update, :destroy]
    end

    class OnCreateDestroy < ::ActiveRecord::Base
      self.table_name = "companies"
      audited on: [:create, :destroy]
    end

    class OnCreateDestroyUser < ::ActiveRecord::Base
      self.table_name = "users"
      audited on: [:create, :destroy]
    end

    class OnCreateDestroyExceptName < ::ActiveRecord::Base
      self.table_name = "companies"
      audited except: :name, on: [:create, :destroy]
    end

    class OnCreateUpdate < ::ActiveRecord::Base
      self.table_name = "companies"
      audited on: [:create, :update]
    end

    class OnTouchOnly < ::ActiveRecord::Base
      self.table_name = "users"
      audited on: [:touch]
    end
  end
end
