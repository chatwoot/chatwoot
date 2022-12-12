"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ServerChannel = void 0;
exports.getServerChannel = getServerChannel;

var _ws = _interopRequireWildcard(require("ws"));

var _telejson = require("telejson");

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function (nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

class ServerChannel {
  constructor(server) {
    var _this = this;

    this.webSocketServer = void 0;
    this.webSocketServer = new _ws.WebSocketServer({
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
    var data = (0, _telejson.stringify)(event, {
      maxDepth: 15,
      allowFunction: true
    });
    Array.from(this.webSocketServer.clients).filter(function (c) {
      return c.readyState === _ws.default.OPEN;
    }).forEach(function (client) {
      return client.send(data);
    });
  }

}

exports.ServerChannel = ServerChannel;

function getServerChannel(server) {
  return new ServerChannel(server);
}