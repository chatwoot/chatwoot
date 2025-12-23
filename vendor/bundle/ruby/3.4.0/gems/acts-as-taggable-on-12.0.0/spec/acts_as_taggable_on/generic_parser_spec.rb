# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ActsAsTaggableOn::GenericParser do
  it '#parse should return empty array if empty tag string is passed' do
    tag_list = ActsAsTaggableOn::GenericParser.new('')
    expect(tag_list.parse).to be_empty
  end

  it '#parse should separate tags by comma' do
    tag_list = ActsAsTaggableOn::GenericParser.new('cool,data,,I,have')
    expect(tag_list.parse).to eq(%w(cool data I have))
  end
end
