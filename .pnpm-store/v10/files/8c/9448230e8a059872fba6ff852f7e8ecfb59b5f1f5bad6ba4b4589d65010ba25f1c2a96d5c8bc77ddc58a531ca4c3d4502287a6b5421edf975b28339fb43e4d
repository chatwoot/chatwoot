'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

function createBirpc(functions, options) {
  const {
    post,
    on,
    eventNames = [],
    serialize = (i) => i,
    deserialize = (i) => i
  } = options;
  const rpcPromiseMap = /* @__PURE__ */ new Map();
  on(async (data, ...extra) => {
    const msg = deserialize(data);
    if (msg.t === "q") {
      const { m: method, a: args } = msg;
      let result, error;
      try {
        result = await functions[method](...args);
      } catch (e) {
        error = e;
      }
      if (msg.i)
        post(serialize({ t: "s", i: msg.i, r: result, e: error }), ...extra);
    } else {
      const { i: ack, r: result, e: error } = msg;
      const promise = rpcPromiseMap.get(ack);
      if (error)
        promise?.reject(error);
      else
        promise?.resolve(result);
      rpcPromiseMap.delete(ack);
    }
  });
  return new Proxy({}, {
    get(_, method) {
      const sendEvent = (...args) => {
        post(serialize({ m: method, a: args, t: "q" }));
      };
      if (eventNames.includes(method)) {
        sendEvent.asEvent = sendEvent;
        return sendEvent;
      }
      const sendCall = (...args) => {
        return new Promise((resolve, reject) => {
          const id = nanoid();
          rpcPromiseMap.set(id, { resolve, reject });
          post(serialize({ m: method, a: args, i: id, t: "q" }));
        });
      };
      sendCall.asEvent = sendEvent;
      return sendCall;
    }
  });
}
const urlAlphabet = "useandom-26T198340PX75pxJACKVERYMINDBUSHWOLF_GQZbfghjklqvwyzrict";
function nanoid(size = 21) {
  let id = "";
  let i = size;
  while (i--)
    id += urlAlphabet[Math.random() * 64 | 0];
  return id;
}

exports.createBirpc = createBirpc;
