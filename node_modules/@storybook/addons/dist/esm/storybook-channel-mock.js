import Channel from '@storybook/channels';
export function mockChannel() {
  var transport = {
    setHandler: function setHandler() {},
    send: function send() {}
  };
  return new Channel({
    transport: transport
  });
}