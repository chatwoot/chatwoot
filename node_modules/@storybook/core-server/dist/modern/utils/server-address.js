import ip from 'ip';
import { logger } from '@storybook/node-logger';
import detectFreePort from 'detect-port';
export function getServerAddresses(port, host, proto) {
  return {
    address: `${proto}://localhost:${port}/`,
    networkAddress: `${proto}://${host || ip.address()}:${port}/`
  };
}
export var getServerPort = function (port) {
  return detectFreePort(port).catch(function (error) {
    logger.error(error);
    process.exit(-1);
  });
};
export var getServerChannelUrl = function (port, {
  https: https
}) {
  return `${https ? 'wss' : 'ws'}://localhost:${port}/storybook-server-channel`;
};