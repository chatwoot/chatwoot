require 'rails_helper'

shared_examples_for 'access_tokenable' do
  let(:obj) { create(described_class.to_s.underscore) }

  it 'creates access token on create' do
    expect(obj.access_token).not_to be_nil
  end
end
