import Channel from '@storybook/channels';
export function mockChannel() {
  const transport = {
    setHandler: () => {},
    send: () => {}
  };
  return new Channel({
    transport
  });
}