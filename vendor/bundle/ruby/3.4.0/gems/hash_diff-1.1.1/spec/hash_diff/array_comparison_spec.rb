require "spec_helper"

describe HashDiff::Comparison do
  let(:left) {
    [
      {
        foo: 'bar',
        bar: 'foo',
      },
      {
        nested: {
          foo: 'bar',
          bar: {
            one: 'foo1'
          }
        },
      },
      {
        num: 1,
        word: nil
      }
    ]
  }

  def comparison(to_compare)
    HashDiff::Comparison.new(left, to_compare)
  end

  def right
    [
      {
        foo: 'bar',
        bar: 'foo',
      },
      {
        nested: {
          foo: 'bar',
          bar: {
            one: 'foo1'
          }
        },
      },
      {
        num: 1,
        word: nil
      }
    ]
  end

  describe 'when arrays are the same' do
    it 'properly determines equality' do
      expect(comparison(right).diff).to be_empty
    end

    it 'handles empty arrays' do
      expect(HashDiff::Comparison.new([], []).diff).to be_empty
    end
  end

  describe 'when arrays are different' do
    it 'reports arrays as not equal with a different order' do
      # move an item from the end to the beginning
      right_shuffled = right
      popped = right_shuffled.pop
      right_shuffled.unshift(popped)

      expect(comparison(right_shuffled).diff).to_not be_empty
    end

    it 'should a deep comparison' do
      right_with_extra_nested_element = right
      right_with_extra_nested_element[1][:nested][:bar][:two] = 'two'

      expect(comparison(right_with_extra_nested_element).diff).to_not be_empty
    end
  end

end