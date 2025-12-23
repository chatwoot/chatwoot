require "spec_helper"

# not testing proxy_respond_to? hack / 2 methods / deprecation of `version`
# also, an additional 6 around `after_touch` for Versions before 6.
uncovered = (ActiveRecord::VERSION::MAJOR < 6) ? 15 : 9
SingleCov.covered! uncovered: uncovered

class ConditionalPrivateCompany < ::ActiveRecord::Base
  self.table_name = "companies"

  audited if: :foo?

  private def foo?
    true
  end
end

class ConditionalCompany < ::ActiveRecord::Base
  self.table_name = "companies"

  audited if: :public?

  def public?
  end
end

class ExclusiveCompany < ::ActiveRecord::Base
  self.table_name = "companies"
  audited if: proc { false }
end

class ExclusionaryCompany < ::ActiveRecord::Base
  self.table_name = "companies"

  audited unless: :non_profit?

  def non_profit?
  end
end

class ExclusionaryCompany2 < ::ActiveRecord::Base
  self.table_name = "companies"
  audited unless: proc { |c| c.exclusive? }

  def exclusive?
    true
  end
end

class InclusiveCompany < ::ActiveRecord::Base
  self.table_name = "companies"
  audited if: proc { true }
end

class InclusiveCompany2 < ::ActiveRecord::Base
  self.table_name = "companies"
  audited unless: proc { false }
end

class Secret < ::ActiveRecord::Base
  audited
end

class Secret2 < ::ActiveRecord::Base
  audited
  self.non_audited_columns = ["delta", "top_secret", "created_at"]
end

describe Audited::Auditor do
  describe "configuration" do
    it "should include instance methods" do
      expect(Models::ActiveRecord::User.new).to be_a_kind_of(Audited::Auditor::AuditedInstanceMethods)
    end

    it "should include class methods" do
      expect(Models::ActiveRecord::User).to be_a_kind_of(Audited::Auditor::AuditedClassMethods)
    end

    ["created_at", "updated_at", "created_on", "updated_on", "lock_version", "id", "password"].each do |column|
      it "should not audit #{column}" do
        expect(Models::ActiveRecord::User.non_audited_columns).to include(column)
      end
    end

    context "should be configurable which conditions are audited" do
      subject { ConditionalCompany.new.send(:auditing_enabled) }

      context "when condition method is private" do
        subject { ConditionalPrivateCompany.new.send(:auditing_enabled) }

        it { is_expected.to be_truthy }
      end

      context "when passing a method name" do
        context "when conditions are true" do
          before { allow_any_instance_of(ConditionalCompany).to receive(:public?).and_return(true) }
          it { is_expected.to be_truthy }
        end

        context "when conditions are false" do
          before { allow_any_instance_of(ConditionalCompany).to receive(:public?).and_return(false) }
          it { is_expected.to be_falsey }
        end
      end

      context "when passing a Proc" do
        context "when conditions are true" do
          subject { InclusiveCompany.new.send(:auditing_enabled) }

          it { is_expected.to be_truthy }
        end

        context "when conditions are false" do
          subject { ExclusiveCompany.new.send(:auditing_enabled) }
          it { is_expected.to be_falsey }
        end
      end
    end

    context "should be configurable which conditions aren't audited" do
      context "when using a method name" do
        subject { ExclusionaryCompany.new.send(:auditing_enabled) }

        context "when conditions are true" do
          before { allow_any_instance_of(ExclusionaryCompany).to receive(:non_profit?).and_return(true) }
          it { is_expected.to be_falsey }
        end

        context "when conditions are false" do
          before { allow_any_instance_of(ExclusionaryCompany).to receive(:non_profit?).and_return(false) }
          it { is_expected.to be_truthy }
        end
      end

      context "when using a proc" do
        context "when conditions are true" do
          subject { ExclusionaryCompany2.new.send(:auditing_enabled) }
          it { is_expected.to be_falsey }
        end

        context "when conditions are false" do
          subject { InclusiveCompany2.new.send(:auditing_enabled) }
          it { is_expected.to be_truthy }
        end
      end
    end

    it "should be configurable which attributes are not audited via ignored_attributes" do
      Audited.ignored_attributes = ["delta", "top_secret", "created_at", "updated_at"]

      expect(Secret.non_audited_columns).to include("delta", "top_secret", "created_at")
    end

    it "should be configurable which attributes are not audited via non_audited_columns=" do
      expect(Secret2.non_audited_columns).to include("delta", "top_secret", "created_at")
    end

    it "should not save non-audited columns" do
      previous = Models::ActiveRecord::User.non_audited_columns
      begin
        Models::ActiveRecord::User.non_audited_columns += [:favourite_device]

        expect(create_user.audits.first.audited_changes.keys.any? { |col| ["favourite_device", "created_at", "updated_at", "password"].include?(col) }).to eq(false)
      ensure
        Models::ActiveRecord::User.non_audited_columns = previous
      end
    end

    it "should not save other columns than specified in 'only' option" do
      user = Models::ActiveRecord::UserOnlyPassword.create
      user.instance_eval do
        def non_column_attr
          @non_column_attr
        end

        def non_column_attr=(val)
          attribute_will_change!("non_column_attr")
          @non_column_attr = val
        end
      end

      user.password = "password"
      user.non_column_attr = "some value"
      user.save!
      expect(user.audits.last.audited_changes.keys).to eq(%w[password])
    end

    it "should save attributes not specified in 'except' option" do
      user = Models::ActiveRecord::User.create
      user.instance_eval do
        def non_column_attr
          @non_column_attr
        end

        def non_column_attr=(val)
          attribute_will_change!("non_column_attr")
          @non_column_attr = val
        end
      end

      user.password = "password"
      user.non_column_attr = "some value"
      user.save!
      expect(user.audits.last.audited_changes.keys).to eq(%w[non_column_attr])
    end

    it "should redact columns specified in 'redacted' option" do
      redacted = Audited::Auditor::AuditedInstanceMethods::REDACTED
      user = Models::ActiveRecord::UserRedactedPassword.create(password: "password")
      user.save!
      expect(user.audits.last.audited_changes["password"]).to eq(redacted)
      user.password = "new_password"
      user.save!
      expect(user.audits.last.audited_changes["password"]).to eq([redacted, redacted])
    end

    it "should redact columns specified in 'redacted' option when there are multiple specified" do
      redacted = Audited::Auditor::AuditedInstanceMethods::REDACTED
      user =
        Models::ActiveRecord::UserMultipleRedactedAttributes.create(
          password: "password"
        )
      user.save!
      expect(user.audits.last.audited_changes["password"]).to eq(redacted)
      # Saving '[REDACTED]' value for 'ssn' even if value wasn't set explicitly when record was created
      expect(user.audits.last.audited_changes["ssn"]).to eq(redacted)

      user.password = "new_password"
      user.ssn = 987654321
      user.save!
      expect(user.audits.last.audited_changes["password"]).to eq([redacted, redacted])
      expect(user.audits.last.audited_changes["ssn"]).to eq([redacted, redacted])

      # If we haven't changed any attrs from 'redacted' list, audit should not contain these keys
      user.name = "new name"
      user.save!
      expect(user.audits.last.audited_changes).to have_key("name")
      expect(user.audits.last.audited_changes).not_to have_key("password")
      expect(user.audits.last.audited_changes).not_to have_key("ssn")
    end

    it "should redact columns in 'redacted' column with custom option" do
      user = Models::ActiveRecord::UserRedactedPasswordCustomRedaction.create(password: "password")
      user.save!
      expect(user.audits.last.audited_changes["password"]).to eq(["My", "Custom", "Value", 7])
    end

    if ::ActiveRecord::VERSION::MAJOR >= 7
      it "should filter encrypted attributes" do
        user = Models::ActiveRecord::UserWithEncryptedPassword.create(password: "password")
        user.save
        expect(user.audits.last.audited_changes["password"]).to eq("[FILTERED]")
      end
    end

    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      describe "'json' and 'jsonb' audited_changes column type" do
        let(:migrations_path) { SPEC_ROOT.join("support/active_record/postgres") }

        after do
          run_migrations(:down, migrations_path)
        end

        it "should work if column type is 'json'" do
          run_migrations(:up, migrations_path, 1)
          Audited::Audit.reset_column_information
          expect(Audited::Audit.columns_hash["audited_changes"].sql_type).to eq("json")

          user = Models::ActiveRecord::User.create
          user.name = "new name"
          user.save!
          expect(user.audits.last.audited_changes).to eq({"name" => [nil, "new name"]})
        end

        it "should work if column type is 'jsonb'" do
          run_migrations(:up, migrations_path, 2)
          Audited::Audit.reset_column_information
          expect(Audited::Audit.columns_hash["audited_changes"].sql_type).to eq("jsonb")

          user = Models::ActiveRecord::User.create
          user.name = "new name"
          user.save!
          expect(user.audits.last.audited_changes).to eq({"name" => [nil, "new name"]})
        end
      end
    end
  end

  describe :new do
    it "should allow mass assignment of all unprotected attributes" do
      yesterday = 1.day.ago

      u = Models::ActiveRecord::NoAttributeProtectionUser.new(name: "name",
        username: "username",
        password: "password",
        activated: true,
        suspended_at: yesterday,
        logins: 2)

      expect(u.name).to eq("name")
      expect(u.username).to eq("username")
      expect(u.password).to eq("password")
      expect(u.activated).to eq(true)
      expect(u.suspended_at.to_i).to eq(yesterday.to_i)
      expect(u.logins).to eq(2)
    end
  end

  describe "on create" do
    let(:user) { create_user status: :reliable, audit_comment: "Create" }

    it "should change the audit count" do
      expect {
        user
      }.to change(Audited::Audit, :count).by(1)
    end

    it "should create associated audit" do
      expect(user.audits.count).to eq(1)
    end

    it "should set the action to create" do
      expect(user.audits.first.action).to eq("create")
      expect(Audited::Audit.creates.order(:id).last).to eq(user.audits.first)
      expect(user.audits.creates.count).to eq(1)
      expect(user.audits.updates.count).to eq(0)
      expect(user.audits.destroys.count).to eq(0)
    end

    it "should store all the audited attributes" do
      expect(user.audits.first.audited_changes).to eq(user.audited_attributes)
    end

    it "should store enum value" do
      expect(user.audits.first.audited_changes["status"]).to eq(1)
    end

    context "when store_synthesized_enums is set to true" do
      before { Audited.store_synthesized_enums = true }
      after { Audited.store_synthesized_enums = false }

      it "should store enum value as Rails synthesized value" do
        expect(user.audits.first.audited_changes["status"]).to eq("reliable")
      end
    end

    it "should store comment" do
      expect(user.audits.first.comment).to eq("Create")
    end

    it "should not audit an attribute which is excepted if specified on create or destroy" do
      on_create_destroy_except_name = Models::ActiveRecord::OnCreateDestroyExceptName.create(name: "Bart")
      expect(on_create_destroy_except_name.audits.first.audited_changes.keys.any? { |col| ["name"].include? col }).to eq(false)
    end

    it "should not save an audit if only specified on update/destroy" do
      expect {
        Models::ActiveRecord::OnUpdateDestroy.create!(name: "Bart")
      }.to_not change(Audited::Audit, :count)
    end
  end

  describe "on update" do
    before do
      @user = create_user(name: "Brandon", status: :active, audit_comment: "Update")
    end

    it "should save an audit" do
      expect {
        @user.update_attribute(:name, "Someone")
      }.to change(Audited::Audit, :count).by(1)
      expect {
        @user.update_attribute(:name, "Someone else")
      }.to change(Audited::Audit, :count).by(1)
    end

    it "should set the action to 'update'" do
      @user.update! name: "Changed"
      expect(@user.audits.last.action).to eq("update")
      expect(Audited::Audit.updates.order(:id).last).to eq(@user.audits.last)
      expect(@user.audits.updates.last).to eq(@user.audits.last)
    end

    it "should store the changed attributes" do
      @user.update! name: "Changed"
      expect(@user.audits.last.audited_changes).to eq({"name" => ["Brandon", "Changed"]})
    end

    it "should store changed enum values" do
      @user.update! status: 1
      expect(@user.audits.last.audited_changes["status"]).to eq([0, 1])
    end

    it "should store audit comment" do
      expect(@user.audits.last.comment).to eq("Update")
    end

    it "should not save an audit if only specified on create/destroy" do
      on_create_destroy = Models::ActiveRecord::OnCreateDestroy.create(name: "Bart")
      expect {
        on_create_destroy.update! name: "Changed"
      }.to_not change(Audited::Audit, :count)
    end

    it "should not save an audit if the value doesn't change after type casting" do
      @user.update! logins: 0, activated: true
      expect { @user.update_attribute :logins, "0" }.to_not change(Audited::Audit, :count)
      expect { @user.update_attribute :activated, 1 }.to_not change(Audited::Audit, :count)
      expect { @user.update_attribute :activated, "1" }.to_not change(Audited::Audit, :count)
    end

    describe "with no dirty changes" do
      it "does not create an audit if the record is not changed" do
        expect {
          @user.save!
        }.to_not change(Audited::Audit, :count)
      end

      it "creates an audit when an audit comment is present" do
        expect {
          @user.audit_comment = "Comment"
          @user.save!
        }.to change(Audited::Audit, :count)
      end
    end
  end

  if ::ActiveRecord::VERSION::MAJOR >= 6
    describe "on touch" do
      before do
        @user = create_user(name: "Brandon", status: :active)
      end

      it "should save an audit" do
        expect { @user.touch(:suspended_at) }.to change(Audited::Audit, :count).by(1)
      end

      it "should set the action to 'update'" do
        @user.touch(:suspended_at)
        expect(@user.audits.last.action).to eq("update")
        expect(Audited::Audit.updates.order(:id).last).to eq(@user.audits.last)
        expect(@user.audits.updates.last).to eq(@user.audits.last)
      end

      it "should store the changed attributes" do
        @user.touch(:suspended_at)
        expect(@user.audits.last.audited_changes["suspended_at"][0]).to be_nil
        expect(Time.parse(@user.audits.last.audited_changes["suspended_at"][1].to_s)).to be_within(2.seconds).of(Time.current)
      end

      it "should store audit comment" do
        @user.audit_comment = "Here exists a touch comment"
        @user.touch(:suspended_at)
        expect(@user.audits.last.action).to eq("update")
        expect(@user.audits.last.comment).to eq("Here exists a touch comment")
      end

      it "should not save an audit if only specified on create/destroy" do
        on_create_destroy = Models::ActiveRecord::OnCreateDestroyUser.create(name: "Bart")
        expect {
          on_create_destroy.touch(:suspended_at)
        }.to_not change(Audited::Audit, :count)
      end

      it "should store an audit if touch is the only audit" do
        on_touch = Models::ActiveRecord::OnTouchOnly.create(name: "Bart")
        expect {
          on_touch.update(name: "NotBart")
        }.to_not change(Audited::Audit, :count)
        expect {
          on_touch.touch(:suspended_at)
        }.to change(on_touch.audits, :count).from(0).to(1)

        @user.audits.destroy_all
        expect(@user.audits).to be_empty
        expect {
          @user.touch(:suspended_at)
        }.to change(@user.audits, :count).from(0).to(1)
      end

      context "don't double audit" do
        let(:user) { Models::ActiveRecord::Owner.create(name: "OwnerUser", suspended_at: 1.month.ago, companies_attributes: [{name: "OwnedCompany"}]) }
        let(:company) { user.companies.first }

        it "should only create 1 (create) audit for object" do
          expect(user.audits.count).to eq(1)
          expect(user.audits.first.action).to eq("create")
        end

        it "should only create 1 (create) audit for nested resource" do
          expect(company.audits.count).to eq(1)
          expect(company.audits.first.action).to eq("create")
        end

        context "after creating" do
          it "updating / touching nested resource shouldn't save touch audit on parent object" do
            expect { company.touch(:type) }.not_to change(user.audits, :count)
            expect { company.update(type: "test") }.not_to change(user.audits, :count)
          end

          it "updating / touching parent object shouldn't save previous data" do
            expect { user.touch(:suspended_at) }.to change(user.audits, :count).from(1).to(2)
            expect(user.audits.last.action).to eq("update")
            expect(user.audits.last.audited_changes.keys).to eq(%w[suspended_at])
          end
        end

        context "after updating" do
          it "changing nested resource shouldn't audit owner" do
            expect { user.update(username: "test") }.to change(user.audits, :count).from(1).to(2)
            expect { company.update(type: "test") }.not_to change(user.audits, :count)

            expect { user.touch(:suspended_at) }.to change(user.audits, :count).from(2).to(3)
            expect { company.update(type: "another_test") }.not_to change(user.audits, :count)
          end
        end
      end
    end
  end

  describe "on destroy" do
    before do
      @user = create_user(status: :active)
    end

    it "should save an audit" do
      expect {
        @user.destroy
      }.to change(Audited::Audit, :count)

      expect(@user.audits.size).to eq(2)
    end

    it "should set the action to 'destroy'" do
      @user.destroy

      expect(@user.audits.last.action).to eq("destroy")
      expect(Audited::Audit.destroys.order(:id).last).to eq(@user.audits.last)
      expect(@user.audits.destroys.last).to eq(@user.audits.last)
    end

    it "should store all of the audited attributes" do
      @user.destroy

      expect(@user.audits.last.audited_changes).to eq(@user.audited_attributes)
    end

    it "should store enum value" do
      @user.destroy
      expect(@user.audits.last.audited_changes["status"]).to eq(0)
    end

    it "should be able to reconstruct a destroyed record without history" do
      @user.audits.delete_all
      @user.destroy

      revision = @user.audits.first.revision
      expect(revision.name).to eq(@user.name)
    end

    it "should not save an audit if only specified on create/update" do
      on_create_update = Models::ActiveRecord::OnCreateUpdate.create!(name: "Bart")

      expect {
        on_create_update.destroy
      }.to_not change(Audited::Audit, :count)
    end

    it "should audit dependent destructions" do
      owner = Models::ActiveRecord::Owner.create!
      company = owner.companies.create!

      expect {
        owner.destroy
      }.to change(Audited::Audit, :count)

      expect(company.audits.map { |a| a.action }).to eq(["create", "destroy"])
    end
  end

  describe "on destroy with unsaved object" do
    let(:user) { Models::ActiveRecord::User.new }

    it "should not audit on 'destroy'" do
      expect {
        user.destroy
      }.to_not raise_error

      expect(user.audits).to be_empty
    end
  end

  describe "associated with" do
    let(:owner) { Models::ActiveRecord::Owner.create(name: "Models::ActiveRecord::Owner") }
    let(:owned_company) { Models::ActiveRecord::OwnedCompany.create!(name: "The auditors", owner: owner) }

    it "should record the associated object on create" do
      expect(owned_company.audits.first.associated).to eq(owner)
    end

    it "should store the associated object on update" do
      owned_company.update_attribute(:name, "The Auditors")
      expect(owned_company.audits.last.associated).to eq(owner)
    end

    it "should store the associated object on destroy" do
      owned_company.destroy
      expect(owned_company.audits.last.associated).to eq(owner)
    end
  end

  describe "has associated audits" do
    let!(:owner) { Models::ActiveRecord::Owner.create!(name: "Models::ActiveRecord::Owner") }
    let!(:owned_company) { Models::ActiveRecord::OwnedCompany.create!(name: "The auditors", owner: owner) }

    it "should list the associated audits" do
      expect(owner.associated_audits.length).to eq(1)
      expect(owner.associated_audits.first.auditable).to eq(owned_company)
    end
  end

  describe "max_audits" do
    it "should respect global setting" do
      stub_global_max_audits(10) do
        expect(Models::ActiveRecord::User.audited_options[:max_audits]).to eq(10)
      end
    end

    it "should respect per model setting" do
      stub_global_max_audits(10) do
        expect(Models::ActiveRecord::MaxAuditsUser.audited_options[:max_audits]).to eq(5)
      end
    end

    it "should delete old audits when keeped amount exceeded" do
      stub_global_max_audits(2) do
        user = create_versions(2)
        user.update(name: "John")
        expect(user.audits.pluck(:version)).to eq([2, 3])
      end
    end

    it "should not delete old audits when keeped amount not exceeded" do
      stub_global_max_audits(3) do
        user = create_versions(2)
        user.update(name: "John")
        expect(user.audits.pluck(:version)).to eq([1, 2, 3])
      end
    end

    it "should delete old extra audits after introducing limit" do
      stub_global_max_audits(nil) do
        user = Models::ActiveRecord::User.create!(name: "Brandon", username: "brandon")
        user.update!(name: "Foobar")
        user.update!(name: "Awesome", username: "keepers")
        user.update!(activated: true)

        Audited.max_audits = 3
        Models::ActiveRecord::User.send(:normalize_audited_options)
        user.update!(favourite_device: "Android Phone")
        audits = user.audits

        expect(audits.count).to eq(3)
        expect(audits[0].audited_changes).to include({"name" => ["Foobar", "Awesome"], "username" => ["brandon", "keepers"]})
        expect(audits[1].audited_changes).to eq({"activated" => [nil, true]})
        expect(audits[2].audited_changes).to eq({"favourite_device" => [nil, "Android Phone"]})
      end
    end

    it "should add comment line for combined audit" do
      stub_global_max_audits(2) do
        user = Models::ActiveRecord::User.create!(name: "Foobar 1")
        user.update(name: "Foobar 2", audit_comment: "First audit comment")
        user.update(name: "Foobar 3", audit_comment: "Second audit comment")
        expect(user.audits.first.comment).to match(/First audit comment.+is the result of multiple/m)
      end
    end

    def stub_global_max_audits(max_audits)
      previous_max_audits = Audited.max_audits
      previous_user_audited_options = Models::ActiveRecord::User.audited_options.dup
      begin
        Audited.max_audits = max_audits
        Models::ActiveRecord::User.send(:normalize_audited_options) # reloads audited_options
        yield
      ensure
        Audited.max_audits = previous_max_audits
        Models::ActiveRecord::User.audited_options = previous_user_audited_options
      end
    end
  end

  describe "revisions" do
    let(:user) { create_versions }

    it "should return an Array of Users" do
      expect(user.revisions).to be_a_kind_of(Array)
      user.revisions.each { |version| expect(version).to be_a_kind_of Models::ActiveRecord::User }
    end

    it "should have one revision for a new record" do
      expect(create_user.revisions.size).to eq(1)
    end

    it "should have one revision for each audit" do
      expect(user.audits.size).to eql(user.revisions.size)
    end

    it "should set the attributes for each revision" do
      u = Models::ActiveRecord::User.create(name: "Brandon", username: "brandon")
      u.update! name: "Foobar"
      u.update! name: "Awesome", username: "keepers"

      expect(u.revisions.size).to eql(3)

      expect(u.revisions[0].name).to eql("Brandon")
      expect(u.revisions[0].username).to eql("brandon")

      expect(u.revisions[1].name).to eql("Foobar")
      expect(u.revisions[1].username).to eql("brandon")

      expect(u.revisions[2].name).to eql("Awesome")
      expect(u.revisions[2].username).to eql("keepers")
    end

    it "access to only recent revisions" do
      u = Models::ActiveRecord::User.create(name: "Brandon", username: "brandon")
      u.update! name: "Foobar"
      u.update! name: "Awesome", username: "keepers"

      expect(u.revisions(2).size).to eq(2)

      expect(u.revisions(2)[0].name).to eq("Foobar")
      expect(u.revisions(2)[0].username).to eq("brandon")

      expect(u.revisions(2)[1].name).to eq("Awesome")
      expect(u.revisions(2)[1].username).to eq("keepers")
    end

    it "should be empty if no audits exist" do
      user.audits.delete_all
      expect(user.revisions).to be_empty
    end

    it "should ignore attributes that have been deleted" do
      user.audits.last.update! audited_changes: {old_attribute: "old value"}
      expect { user.revisions }.to_not raise_error
    end
  end

  describe "revisions" do
    let(:user) { create_versions(5) }

    it "should maintain identity" do
      expect(user.revision(1)).to eq(user)
    end

    it "should find the given revision" do
      revision = user.revision(3)
      expect(revision).to be_a_kind_of(Models::ActiveRecord::User)
      expect(revision.audit_version).to eq(3)
      expect(revision.name).to eq("Foobar 3")
    end

    it "should find the previous revision with :previous" do
      revision = user.revision(:previous)
      expect(revision.audit_version).to eq(4)
      # expect(revision).to eq(user.revision(4))
      expect(revision.attributes).to eq(user.revision(4).attributes)
    end

    it "should be able to get the previous revision repeatedly" do
      previous = user.revision(:previous)
      expect(previous.audit_version).to eq(4)
      expect(previous.revision(:previous).audit_version).to eq(3)
    end

    it "should be able to set protected attributes" do
      u = Models::ActiveRecord::User.create(name: "Brandon")
      u.update_attribute :logins, 1
      u.update_attribute :logins, 2

      expect(u.revision(3).logins).to eq(2)
      expect(u.revision(2).logins).to eq(1)
      expect(u.revision(1).logins).to eq(0)
    end

    it "should set attributes directly" do
      u = Models::ActiveRecord::User.create(name: "<Joe>")
      expect(u.revision(1).name).to eq("&lt;Joe&gt;")
    end

    it "should set the attributes for each revision" do
      u = Models::ActiveRecord::User.create(name: "Brandon", username: "brandon")
      u.update! name: "Foobar"
      u.update! name: "Awesome", username: "keepers"

      expect(u.revision(3).name).to eq("Awesome")
      expect(u.revision(3).username).to eq("keepers")

      expect(u.revision(2).name).to eq("Foobar")
      expect(u.revision(2).username).to eq("brandon")

      expect(u.revision(1).name).to eq("Brandon")
      expect(u.revision(1).username).to eq("brandon")
    end

    it "should correctly restore revision with enum" do
      u = Models::ActiveRecord::User.create(status: :active)
      u.update_attribute(:status, :reliable)
      u.update_attribute(:status, :banned)

      expect(u.revision(3)).to be_banned
      expect(u.revision(2)).to be_reliable
      expect(u.revision(1)).to be_active
    end

    it "should be able to get time for first revision" do
      suspended_at = Time.zone.now
      u = Models::ActiveRecord::User.create(suspended_at: suspended_at)
      expect(u.revision(1).suspended_at.to_s).to eq(suspended_at.to_s)
    end

    it "should not raise an error when no previous audits exist" do
      user.audits.destroy_all
      expect { user.revision(:previous) }.to_not raise_error
    end

    it "should mark revision's attributes as changed" do
      expect(user.revision(1).name_changed?).to eq(true)
    end

    it "should record new audit when saving revision" do
      expect {
        user.revision(1).save!
      }.to change(user.audits, :count).by(1)
    end

    it "should re-insert destroyed records" do
      user.destroy
      expect {
        user.revision(1).save!
      }.to change(Models::ActiveRecord::User, :count).by(1)
    end

    it "should return nil for values greater than the number of revisions" do
      expect(user.revision(user.revisions.count + 1)).to be_nil
    end

    it "should work with array attributes" do
      u = Models::ActiveRecord::User.create!(phone_numbers: ["+1 800-444-4444"])
      u.update!(phone_numbers: ["+1 804-222-1111", "+1 317 222-2222"])

      expect(u.revision(0).phone_numbers).to eq(["+1 804-222-1111", "+1 317 222-2222"])
      expect(u.revision(1).phone_numbers).to eq(["+1 800-444-4444"])
    end
  end

  describe "revision_at" do
    let(:user) { create_user }

    it "should find the latest revision before the given time" do
      audit = user.audits.first
      audit.created_at = 1.hour.ago
      audit.save!
      user.update! name: "updated"
      expect(user.revision_at(2.minutes.ago).audit_version).to eq(1)
    end

    it "should be nil if given a time before audits" do
      expect(user.revision_at(1.week.ago)).to be_nil
    end
  end

  describe "own_and_associated_audits" do
    it "should return audits for self and associated audits" do
      owner = Models::ActiveRecord::Owner.create!
      company = owner.companies.create!
      company.update!(name: "Collective Idea")

      other_owner = Models::ActiveRecord::Owner.create!
      other_owner.companies.create!

      expect(owner.own_and_associated_audits).to match_array(owner.audits + company.audits)
    end

    it "should return audits for STI classes" do
      # Where parent is STI
      sti_company = Models::ActiveRecord::Company::STICompany.create!
      sti_company.update!(name: "Collective Idea")
      expect(sti_company.own_and_associated_audits).to match_array(sti_company.audits)

      # Where associated is STI
      owner = Models::ActiveRecord::Owner.create!
      company = owner.companies.create! type: "Models::ActiveRecord::OwnedCompany::STICompany"
      company.update!(name: "Collective Idea")
      expect(owner.own_and_associated_audits).to match_array(owner.audits + company.audits)
    end

    it "should order audits by creation time" do
      owner = Models::ActiveRecord::Owner.create!
      first_audit = owner.audits.first
      first_audit.update_column(:created_at, 1.year.ago)

      company = owner.companies.create!
      second_audit = company.audits.first
      second_audit.update_column(:created_at, 1.month.ago)

      company.update!(name: "Collective Idea")
      third_audit = company.audits.last
      expect(owner.own_and_associated_audits.to_a).to eq([third_audit, second_audit, first_audit])
    end
  end

  describe "without auditing" do
    it "should not save an audit when calling #save_without_auditing" do
      expect {
        u = Models::ActiveRecord::User.new(name: "Brandon")
        expect(u.save_without_auditing).to eq(true)
      }.to_not change(Audited::Audit, :count)
    end

    it "should not save an audit inside of the #without_auditing block" do
      expect {
        Models::ActiveRecord::User.without_auditing { Models::ActiveRecord::User.create!(name: "Brandon") }
      }.to_not change(Audited::Audit, :count)
    end

    context "when global audits are disabled" do
      it "should re-enable class audits after #without_auditing block" do
        Audited.auditing_enabled = false
        Models::ActiveRecord::User.without_auditing {}
        Audited.auditing_enabled = true
        expect(Models::ActiveRecord::User.auditing_enabled).to eql(true)
      end
    end

    it "should reset auditing status even it raises an exception" do
      begin
        Models::ActiveRecord::User.without_auditing { raise }
      rescue
        nil
      end
      expect(Models::ActiveRecord::User.auditing_enabled).to eq(true)
    end

    it "should be thread safe using a #without_auditing block" do
      skip if Models::ActiveRecord::User.connection.class.name.include?("SQLite")

      t1 = Thread.new do
        expect(Models::ActiveRecord::User.auditing_enabled).to eq(true)
        Models::ActiveRecord::User.without_auditing do
          expect(Models::ActiveRecord::User.auditing_enabled).to eq(false)
          Models::ActiveRecord::User.create!(name: "Bart")
          sleep 1
          expect(Models::ActiveRecord::User.auditing_enabled).to eq(false)
        end
        expect(Models::ActiveRecord::User.auditing_enabled).to eq(true)
      end

      t2 = Thread.new do
        sleep 0.5
        expect(Models::ActiveRecord::User.auditing_enabled).to eq(true)
        Models::ActiveRecord::User.create!(name: "Lisa")
      end
      t1.join
      t2.join

      expect(Models::ActiveRecord::User.find_by_name("Bart").audits.count).to eq(0)
      expect(Models::ActiveRecord::User.find_by_name("Lisa").audits.count).to eq(1)
    end

    it "should not save an audit when auditing is globally disabled" do
      expect(Audited.auditing_enabled).to eq(true)
      Audited.auditing_enabled = false
      expect(Models::ActiveRecord::User.auditing_enabled).to eq(false)

      user = create_user
      expect(user.audits.count).to eq(0)

      Audited.auditing_enabled = true
      expect(Models::ActiveRecord::User.auditing_enabled).to eq(true)

      user.update!(name: "Test")
      expect(user.audits.count).to eq(1)
      Models::ActiveRecord::User.enable_auditing
    end
  end

  describe "with auditing" do
    it "should save an audit when calling #save_with_auditing" do
      expect {
        u = Models::ActiveRecord::User.new(name: "Brandon")
        Models::ActiveRecord::User.auditing_enabled = false
        expect(u.save_with_auditing).to eq(true)
        Models::ActiveRecord::User.auditing_enabled = true
      }.to change(Audited::Audit, :count).by(1)
    end

    it "should save an audit inside of the #with_auditing block" do
      expect {
        Models::ActiveRecord::User.auditing_enabled = false
        Models::ActiveRecord::User.with_auditing { Models::ActiveRecord::User.create!(name: "Brandon") }
        Models::ActiveRecord::User.auditing_enabled = true
      }.to change(Audited::Audit, :count).by(1)
    end

    context "when global audits are disabled" do
      it "should re-enable class audits after #with_auditing block" do
        Audited.auditing_enabled = false
        Models::ActiveRecord::User.with_auditing {}
        Audited.auditing_enabled = true
        expect(Models::ActiveRecord::User.auditing_enabled).to eql(true)
      end
    end

    it "should reset auditing status even it raises an exception" do
      Models::ActiveRecord::User.disable_auditing
      begin
        Models::ActiveRecord::User.with_auditing { raise }
      rescue
        nil
      end
      expect(Models::ActiveRecord::User.auditing_enabled).to eq(false)
      Models::ActiveRecord::User.enable_auditing
    end

    it "should be thread safe using a #with_auditing block" do
      skip if Models::ActiveRecord::User.connection.class.name.include?("SQLite")

      t1 = Thread.new do
        Models::ActiveRecord::User.disable_auditing
        expect(Models::ActiveRecord::User.auditing_enabled).to eq(false)
        Models::ActiveRecord::User.with_auditing do
          expect(Models::ActiveRecord::User.auditing_enabled).to eq(true)

          Models::ActiveRecord::User.create!(name: "Shaggy")
          sleep 1
          expect(Models::ActiveRecord::User.auditing_enabled).to eq(true)
        end
        expect(Models::ActiveRecord::User.auditing_enabled).to eq(false)
        Models::ActiveRecord::User.enable_auditing
      end

      t2 = Thread.new do
        sleep 0.5
        Models::ActiveRecord::User.disable_auditing
        expect(Models::ActiveRecord::User.auditing_enabled).to eq(false)
        Models::ActiveRecord::User.create!(name: "Scooby")
        Models::ActiveRecord::User.enable_auditing
      end
      t1.join
      t2.join

      Models::ActiveRecord::User.enable_auditing
      expect(Models::ActiveRecord::User.find_by_name("Shaggy").audits.count).to eq(1)
      expect(Models::ActiveRecord::User.find_by_name("Scooby").audits.count).to eq(0)
    end
  end

  describe "comment required" do
    describe "on create" do
      it "should not validate when audit_comment is not supplied when initialized" do
        expect(Models::ActiveRecord::CommentRequiredUser.new(name: "Foo")).not_to be_valid
      end

      it "should not validate when audit_comment is not supplied trying to create" do
        expect(Models::ActiveRecord::CommentRequiredUser.create(name: "Foo")).not_to be_valid
      end

      it "should validate when audit_comment is supplied" do
        expect(Models::ActiveRecord::CommentRequiredUser.create(name: "Foo", audit_comment: "Create")).to be_valid
      end

      it "should validate when audit_comment is not supplied, and creating is not being audited" do
        expect(Models::ActiveRecord::OnUpdateCommentRequiredUser.create(name: "Foo")).to be_valid
        expect(Models::ActiveRecord::OnDestroyCommentRequiredUser.create(name: "Foo")).to be_valid
      end

      it "should validate when audit_comment is not supplied, and auditing is disabled" do
        Models::ActiveRecord::CommentRequiredUser.disable_auditing
        expect(Models::ActiveRecord::CommentRequiredUser.create(name: "Foo")).to be_valid
        Models::ActiveRecord::CommentRequiredUser.enable_auditing
      end

      it "should validate when audit_comment is not supplied, and only excluded attributes changed" do
        expect(Models::ActiveRecord::CommentRequiredUser.new(password: "Foo")).to be_valid
      end
    end

    describe "on update" do
      let(:user) { Models::ActiveRecord::CommentRequiredUser.create!(audit_comment: "Create") }
      let(:on_create_user) { Models::ActiveRecord::OnDestroyCommentRequiredUser.create }
      let(:on_destroy_user) { Models::ActiveRecord::OnDestroyCommentRequiredUser.create }

      it "should not validate when audit_comment is not supplied" do
        expect(user.update(name: "Test")).to eq(false)
      end

      it "should validate when audit_comment is not supplied, and updating is not being audited" do
        expect(on_create_user.update(name: "Test")).to eq(true)
        expect(on_destroy_user.update(name: "Test")).to eq(true)
      end

      it "should validate when audit_comment is supplied" do
        expect(user.update(name: "Test", audit_comment: "Update")).to eq(true)
      end

      it "should validate when audit_comment is not supplied, and auditing is disabled" do
        Models::ActiveRecord::CommentRequiredUser.disable_auditing
        expect(user.update(name: "Test")).to eq(true)
        Models::ActiveRecord::CommentRequiredUser.enable_auditing
      end

      it "should validate when audit_comment is not supplied, and only excluded attributes changed" do
        expect(user.update(password: "Test")).to eq(true)
      end
    end

    describe "on destroy" do
      let(:user) { Models::ActiveRecord::CommentRequiredUser.create!(audit_comment: "Create") }
      let(:on_create_user) { Models::ActiveRecord::OnCreateCommentRequiredUser.create!(audit_comment: "Create") }
      let(:on_update_user) { Models::ActiveRecord::OnUpdateCommentRequiredUser.create }

      it "should not validate when audit_comment is not supplied" do
        expect(user.destroy).to eq(false)
      end

      it "should validate when audit_comment is supplied" do
        user.audit_comment = "Destroy"
        expect(user.destroy).to eq(user)
      end

      it "should validate when audit_comment is not supplied, and destroying is not being audited" do
        expect(on_create_user.destroy).to eq(on_create_user)
        expect(on_update_user.destroy).to eq(on_update_user)
      end

      it "should validate when audit_comment is not supplied, and auditing is disabled" do
        Models::ActiveRecord::CommentRequiredUser.disable_auditing
        expect(user.destroy).to eq(user)
        Models::ActiveRecord::CommentRequiredUser.enable_auditing
      end
    end
  end

  describe "no update with comment only" do
    let(:user) { Models::ActiveRecord::NoUpdateWithCommentOnlyUser.create }

    it "does not create an audit when only an audit_comment is present" do
      user.audit_comment = "Comment"
      expect { user.save! }.to_not change(Audited::Audit, :count)
    end
  end

  describe "attr_protected and attr_accessible" do
    it "should not raise error when attr_accessible is set and protected is false" do
      expect {
        Models::ActiveRecord::AccessibleAfterDeclarationUser.new(name: "No fail!")
      }.to_not raise_error
    end

    it "should not rause an error when attr_accessible is declared before audited" do
      expect {
        Models::ActiveRecord::AccessibleAfterDeclarationUser.new(name: "No fail!")
      }.to_not raise_error
    end
  end

  describe "audit_as" do
    let(:user) { Models::ActiveRecord::User.create name: "Testing" }

    it "should record user objects" do
      Models::ActiveRecord::Company.audit_as(user) do
        company = Models::ActiveRecord::Company.create name: "The auditors"
        company.update! name: "The Auditors"

        company.audits.each do |audit|
          expect(audit.user).to eq(user)
        end
      end
    end

    it "should record usernames" do
      Models::ActiveRecord::Company.audit_as(user.name) do
        company = Models::ActiveRecord::Company.create name: "The auditors"
        company.update! name: "The Auditors"

        company.audits.each do |audit|
          expect(audit.user).to eq(user.name)
        end
      end
    end
  end

  describe "after_audit" do
    let(:user) { Models::ActiveRecord::UserWithAfterAudit.new }

    it "should invoke after_audit callback on create" do
      expect(user.bogus_attr).to be_nil
      expect(user.save).to eq(true)
      expect(user.bogus_attr).to eq("do something")
    end
  end

  describe "around_audit" do
    let(:user) { Models::ActiveRecord::UserWithAfterAudit.new }

    it "should invoke around_audit callback on create" do
      expect(user.around_attr).to be_nil
      expect(user.save).to eq(true)
      expect(user.around_attr).to eq(user.audits.last)
    end
  end

  describe "STI auditing" do
    it "should correctly disable auditing when using STI" do
      company = Models::ActiveRecord::Company::STICompany.create name: "The auditors"
      expect(company.type).to eq("Models::ActiveRecord::Company::STICompany")
      expect {
        Models::ActiveRecord::Company.auditing_enabled = false
        company.update! name: "STI auditors"
        Models::ActiveRecord::Company.auditing_enabled = true
      }.to_not change(Audited::Audit, :count)
    end
  end
end
