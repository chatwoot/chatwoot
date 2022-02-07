require 'rails_helper'

shared_examples_for 'reauthorizable' do
  let(:model) { described_class } # the class that includes the concern

  it 'authorization_error!' do
    obj = FactoryBot.create(model.to_s.underscore.tr('/', '_').to_sym)
    expect(obj.authorization_error_count).to eq 0

    obj.authorization_error!

    expect(obj.authorization_error_count).to eq 1
  end

  it 'prompt_reauthorization!' do
    obj = FactoryBot.create(model.to_s.underscore.tr('/', '_').to_sym)
    expect(obj.reauthorization_required?).to eq false

    obj.prompt_reauthorization!

    expect(obj.reauthorization_required?).to eq true
  end

  it 'reauthorized!' do
    obj = FactoryBot.create(model.to_s.underscore.tr('/', '_').to_sym)
    # setting up the object with the errors to validate its cleared on action
    obj.authorization_error!
    obj.prompt_reauthorization!
    expect(obj.reauthorization_required?).to eq true
    expect(obj.authorization_error_count).not_to eq 0

    obj.reauthorized!

    # authorization errors are reset
    expect(obj.authorization_error_count).to eq 0
    expect(obj.reauthorization_required?).to eq false
  end
end
