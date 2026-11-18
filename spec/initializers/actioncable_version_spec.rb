require 'rails_helper'

# rubocop:disable RSpec/DescribeClass -- the subject is the Listener patch in config/initializers/actioncable.rb.
describe 'Action Cable Redis listener patch' do
  it 'runs on the actioncable minor its overrides were written against' do
    expect(ActionCable.gem_version.segments.first(2)).to eq([8, 0]), <<~MESSAGE.squish
      actioncable is #{ActionCable.gem_version}, but ActionCableRedisListenerRecovery in
      config/initializers/actioncable.rb overrides private methods of the actioncable 8.0 Redis
      Listener (unchanged from 7.2). Read the Listener of this version and the state of rails/rails#58939 and
      rails/rails#59043, adjust or drop the patch, then update this pin.
    MESSAGE
  end
end
# rubocop:enable RSpec/DescribeClass
