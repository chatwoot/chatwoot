import WebSocket, { WebSocketServer } from 'ws';
import { stringify } from 'telejson';
export class ServerChannel {
  constructor(server) {
    var _this = this;

    this.webSocketServer = void 0;
    this.webSocketServer = new WebSocketServer({
      noServer: true
    });
    server.on('upgrade', function (request, socket, head) {
      if (request.url === '/storybook-server-channel') {
        _this.webSocketServer.handleUpgrade(request, socket, head, function (ws) {
          _this.webSocketServer.emit('connection', ws, request);
        });
      }
    });
  }

  emit(type, args = []) {
    var event = {
      type: type,
      args: args
    };
    var data = stringify(event, {
      maxDepth: 15,
      allowFunction: true
    });
    Array.from(this.webSocketServer.clients).filter(function (c) {
      return c.readyState === WebSocket.OPEN;
    }).forEach(function (client) {
      return client.send(data);
    });
  }

}
export function getServerChannel(server) {
  return new ServerChannel(server);
}