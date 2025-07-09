// src/entry/utils.ts
import { pathToFileURL } from "url";
var importESMCached;
function getImportESM() {
  if (importESMCached === void 0) {
    importESMCached = new Function(
      "specifier",
      "return import(specifier)"
    );
  }
  return importESMCached;
}
var handlerCache = /* @__PURE__ */ new Map();
async function getHandler(filename, name) {
  let handler = handlerCache.get(`${filename}/${name}`);
  if (handler !== void 0) {
    return handler;
  }
  try {
    const handlerModule = await import(filename);
    handler = typeof handlerModule.default !== "function" && handlerModule.default || handlerModule;
    if (typeof handler !== "function") {
      handler = await handler[name];
    }
  } catch {
  }
  if (typeof handler !== "function") {
    handler = await getImportESM()(pathToFileURL(filename).href);
    if (typeof handler !== "function") {
      handler = await handler[name];
    }
  }
  if (typeof handler !== "function") {
    return null;
  }
  if (handlerCache.size > 1e3) {
    const [handler2] = handlerCache;
    const key = handler2[0];
    handlerCache.delete(key);
  }
  handlerCache.set(`${filename}/${name}`, handler);
  return handler;
}
function throwInNextTick(error) {
  process.nextTick(() => {
    throw error;
  });
}

export {
  getHandler,
  throwInNextTick
};
