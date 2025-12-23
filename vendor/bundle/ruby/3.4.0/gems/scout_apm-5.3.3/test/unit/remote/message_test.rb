require 'test_helper'

class MessageTest < Minitest::Test
  def test_message_encode_decode_roundtrip
    message = ScoutApm::Remote::Message.new('type', 'command', ['arg'])
    encoded = message.encode
    decoded = ScoutApm::Remote::Message.decode(encoded)
    assert_equal message.type, decoded.type
    assert_equal message.command, decoded.command
    assert_equal message.args, decoded.args
  end
end

