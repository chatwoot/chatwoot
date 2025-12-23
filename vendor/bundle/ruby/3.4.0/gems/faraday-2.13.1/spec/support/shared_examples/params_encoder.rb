# frozen_string_literal: true

shared_examples 'a params encoder' do
  it 'escapes safe buffer' do
    monies = FakeSafeBuffer.new('$32,000.00')
    expect(subject.encode('a' => monies)).to eq('a=%2432%2C000.00')
  end

  it 'raises type error for empty string' do
    expect { subject.encode('') }.to raise_error(TypeError) do |error|
      expect(error.message).to eq("Can't convert String into Hash.")
    end
  end

  it 'encodes nil' do
    expect(subject.encode('a' => nil)).to eq('a')
  end
end
