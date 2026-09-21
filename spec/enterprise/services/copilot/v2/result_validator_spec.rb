require 'rails_helper'

RSpec.describe Copilot::V2::ResultValidator do
  let(:validator) { described_class.new('mode' => 'classify', 'instruction' => 'Find slowness', 'fields' => []) }
  let(:inputs) do
    [{ 'record_id' => 10, 'evidence' => [{ 'id' => 20, 'parts' => [{ 'id' => 'message:20:body', 'text' => 'slow' }] }], 'limitations' => [] }]
  end
  let(:row) do
    { 'record_id' => 10, 'decision' => 'match', 'reason' => 'Direct statement', 'values' => {},
      'citations' => [{ 'record_id' => 20, 'part_id' => 'message:20:body' }] }
  end

  it 'rejects foreign parts, duplicate records and unsupported positive findings' do
    expect(validator.validate!({ 'results' => [row] }, inputs)).to eq([row])
    expect { validator.validate!({ 'results' => [row, row] }, inputs) }.to raise_error(ArgumentError)
    row['citations'][0]['part_id'] = 'message:21:body'
    expect { validator.validate!({ 'results' => [row] }, inputs) }.to raise_error(ArgumentError)
    row['citations'] = []
    expect { validator.validate!({ 'results' => [row] }, inputs) }.to raise_error(ArgumentError)
  end

  it 'requires uncertainty for empty or incomplete evidence without treating it as an unresolved failure' do
    inputs[0]['evidence'] = []
    row.merge!('decision' => 'no_match', 'citations' => [])
    expect { validator.validate!({ 'results' => [row] }, inputs) }.to raise_error(ArgumentError)
    row['decision'] = 'uncertain'
    expect(validator.validate!({ 'results' => [row] }, inputs)).to eq([row])
  end

  it 'allows missing extracted values to remain null instead of inventing numbers or enums' do
    specification = { 'mode' => 'extract', 'instruction' => 'Extract priority and age', 'fields' => [
      { 'name' => 'age', 'type' => 'integer', 'values' => [] },
      { 'name' => 'priority', 'type' => 'string', 'values' => ['urgent'] }
    ] }
    extraction = described_class.new(specification)
    row.merge!('decision' => 'uncertain', 'values' => { 'age' => nil, 'priority' => nil }, 'citations' => [])
    expect(extraction.validate!({ 'results' => [row] }, inputs)).to eq([row])
  end
end
