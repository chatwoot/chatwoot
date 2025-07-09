import './vue.runtime.esm-bundler.js';

var isVue2 = false;
var isVue3 = true;
var Vue2 = undefined;

function install() {}

function set(target, key, val) {
  if (Array.isArray(target)) {
    target.length = Math.max(target.length, key);
    target.splice(key, 1, val);
    return val
  }
  target[key] = val;
  return val
}

function del(target, key) {
  if (Array.isArray(target)) {
    target.splice(key, 1);
    return
  }
  delete target[key];
}

export { isVue3 as a, del as d, isVue2 as i, set as s };
