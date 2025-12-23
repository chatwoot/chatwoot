require "spec_helper"

describe Models::ActiveRecord::UserExceptPassword do
  let(:non_audited_columns) { subject.class.non_audited_columns }

  it { should_not be_audited.only(non_audited_columns) }
  it { should be_audited.except(:password) }
  it { should_not be_audited.requires_comment }
  it { should be_audited.on(:create, :update, :destroy) }
  # test chaining
  it { should be_audited.except(:password).on(:create, :update, :destroy) }
end

describe Models::ActiveRecord::UserOnlyPassword do
  let(:audited_columns) { subject.class.audited_columns }

  it { should be_audited.only(:password) }
  it { should_not be_audited.except(audited_columns) }
  it { should_not be_audited.requires_comment }
  it { should be_audited.on(:create, :update, :destroy) }
  it { should be_audited.only(:password).on(:create, :update, :destroy) }
end

describe Models::ActiveRecord::CommentRequiredUser do
  let(:audited_columns) { subject.class.audited_columns }
  let(:non_audited_columns) { subject.class.non_audited_columns }

  it { should_not be_audited.only(non_audited_columns) }
  it { should_not be_audited.except(audited_columns) }
  it { should be_audited.requires_comment }
  it { should be_audited.on(:create, :update, :destroy) }
  it { should be_audited.requires_comment.on(:create, :update, :destroy) }
end

describe Models::ActiveRecord::OnCreateCommentRequiredUser do
  let(:audited_columns) { subject.class.audited_columns }
  let(:non_audited_columns) { subject.class.non_audited_columns }

  it { should_not be_audited.only(non_audited_columns) }
  it { should_not be_audited.except(audited_columns) }
  it { should be_audited.requires_comment }
  it { should be_audited.on(:create) }
  it { should_not be_audited.on(:update, :destroy) }
  it { should be_audited.requires_comment.on(:create) }
end

describe Models::ActiveRecord::OnUpdateCommentRequiredUser do
  let(:audited_columns) { subject.class.audited_columns }
  let(:non_audited_columns) { subject.class.non_audited_columns }

  it { should_not be_audited.only(non_audited_columns) }
  it { should_not be_audited.except(audited_columns) }
  it { should be_audited.requires_comment }
  it { should be_audited.on(:update) }
  it { should_not be_audited.on(:create, :destroy) }
  it { should be_audited.requires_comment.on(:update) }
end

describe Models::ActiveRecord::OnDestroyCommentRequiredUser do
  let(:audited_columns) { subject.class.audited_columns }
  let(:non_audited_columns) { subject.class.non_audited_columns }

  it { should_not be_audited.only(non_audited_columns) }
  it { should_not be_audited.except(audited_columns) }
  it { should be_audited.requires_comment }
  it { should be_audited.on(:destroy) }
  it { should_not be_audited.on(:create, :update) }
  it { should be_audited.requires_comment.on(:destroy) }
end
