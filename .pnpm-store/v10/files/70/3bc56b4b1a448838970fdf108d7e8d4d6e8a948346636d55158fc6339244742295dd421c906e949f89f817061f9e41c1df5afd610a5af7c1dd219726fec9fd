/*!
 * hotkeys-js v3.8.7
 * A simple micro-library for defining and dispatching keyboard shortcuts. It has no dependencies.
 * 
 * Copyright (c) 2021 kenny wong <wowohoo@qq.com>
 * http://jaywcjlove.github.io/hotkeys
 * 
 * Licensed under the MIT license.
 */

(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.hotkeys = factory());
}(this, (function () { 'use strict';

  var isff = typeof navigator !== 'undefined' ? navigator.userAgent.toLowerCase().indexOf('firefox') > 0 : false; // 绑定事件

  function addEvent(object, event, method) {
    if (object.addEventListener) {
      object.addEventListener(event, method, false);
    } else if (object.attachEvent) {
      object.attachEvent("on".concat(event), function () {
        method(window.event);
      });
    }
  } // 修饰键转换成对应的键码


  function getMods(modifier, key) {
    var mods = key.slice(0, key.length - 1);

    for (var i = 0; i < mods.length; i++) {
      mods[i] = modifier[mods[i].toLowerCase()];
    }

    return mods;
  } // 处理传的key字符串转换成数组


  function getKeys(key) {
    if (typeof key !== 'string') key = '';
    key = key.replace(/\s/g, ''); // 匹配任何空白字符,包括空格、制表符、换页符等等

    var keys = key.split(','); // 同时设置多个快捷键，以','分割

    var index = keys.lastIndexOf(''); // 快捷键可能包含','，需特殊处理

    for (; index >= 0;) {
      keys[index - 1] += ',';
      keys.splice(index, 1);
      index = keys.lastIndexOf('');
    }

    return keys;
  } // 比较修饰键的数组


  function compareArray(a1, a2) {
    var arr1 = a1.length >= a2.length ? a1 : a2;
    var arr2 = a1.length >= a2.length ? a2 : a1;
    var isIndex = true;

    for (var i = 0; i < arr1.length; i++) {
      if (arr2.indexOf(arr1[i]) === -1) isIndex = false;
    }

    return isIndex;
  }

  var _keyMap = {
    backspace: 8,
    tab: 9,
    clear: 12,
    enter: 13,
    return: 13,
    esc: 27,
    escape: 27,
    space: 32,
    left: 37,
    up: 38,
    right: 39,
    down: 40,
    del: 46,
    delete: 46,
    ins: 45,
    insert: 45,
    home: 36,
    end: 35,
    pageup: 33,
    pagedown: 34,
    capslock: 20,
    num_0: 96,
    num_1: 97,
    num_2: 98,
    num_3: 99,
    num_4: 100,
    num_5: 101,
    num_6: 102,
    num_7: 103,
    num_8: 104,
    num_9: 105,
    num_multiply: 106,
    num_add: 107,
    num_enter: 108,
    num_subtract: 109,
    num_decimal: 110,
    num_divide: 111,
    '⇪': 20,
    ',': 188,
    '.': 190,
    '/': 191,
    '`': 192,
    '-': isff ? 173 : 189,
    '=': isff ? 61 : 187,
    ';': isff ? 59 : 186,
    '\'': 222,
    '[': 219,
    ']': 221,
    '\\': 220
  }; // Modifier Keys

  var _modifier = {
    // shiftKey
    '⇧': 16,
    shift: 16,
    // altKey
    '⌥': 18,
    alt: 18,
    option: 18,
    // ctrlKey
    '⌃': 17,
    ctrl: 17,
    control: 17,
    // metaKey
    '⌘': 91,
    cmd: 91,
    command: 91
  };
  var modifierMap = {
    16: 'shiftKey',
    18: 'altKey',
    17: 'ctrlKey',
    91: 'metaKey',
    shiftKey: 16,
    ctrlKey: 17,
    altKey: 18,
    metaKey: 91
  };
  var _mods = {
    16: false,
    18: false,
    17: false,
    91: false
  };
  var _handlers = {}; // F1~F12 special key

  for (var k = 1; k < 20; k++) {
    _keyMap["f".concat(k)] = 111 + k;
  }

  var _downKeys = []; // 记录摁下的绑定键

  var _scope = 'all'; // 默认热键范围

  var elementHasBindEvent = []; // 已绑定事件的节点记录
  // 返回键码

  var code = function code(x) {
    return _keyMap[x.toLowerCase()] || _modifier[x.toLowerCase()] || x.toUpperCase().charCodeAt(0);
  }; // 设置获取当前范围（默认为'所有'）


  function setScope(scope) {
    _scope = scope || 'all';
  } // 获取当前范围


  function getScope() {
    return _scope || 'all';
  } // 获取摁下绑定键的键值


  function getPressedKeyCodes() {
    return _downKeys.slice(0);
  } // 表单控件控件判断 返回 Boolean
  // hotkey is effective only when filter return true


  function filter(event) {
    var target = event.target || event.srcElement;
    var tagName = target.tagName;
    var flag = true; // ignore: isContentEditable === 'true', <input> and <textarea> when readOnly state is false, <select>

    if (target.isContentEditable || (tagName === 'INPUT' || tagName === 'TEXTAREA' || tagName === 'SELECT') && !target.readOnly) {
      flag = false;
    }

    return flag;
  } // 判断摁下的键是否为某个键，返回true或者false


  function isPressed(keyCode) {
    if (typeof keyCode === 'string') {
      keyCode = code(keyCode); // 转换成键码
    }

    return _downKeys.indexOf(keyCode) !== -1;
  } // 循环删除handlers中的所有 scope(范围)


  function deleteScope(scope, newScope) {
    var handlers;
    var i; // 没有指定scope，获取scope

    if (!scope) scope = getScope();

    for (var key in _handlers) {
      if (Object.prototype.hasOwnProperty.call(_handlers, key)) {
        handlers = _handlers[key];

        for (i = 0; i < handlers.length;) {
          if (handlers[i].scope === scope) handlers.splice(i, 1);else i++;
        }
      }
    } // 如果scope被删除，将scope重置为all


    if (getScope() === scope) setScope(newScope || 'all');
  } // 清除修饰键


  function clearModifier(event) {
    var key = event.keyCode || event.which || event.charCode;

    var i = _downKeys.indexOf(key); // 从列表中清除按压过的键


    if (i >= 0) {
      _downKeys.splice(i, 1);
    } // 特殊处理 cmmand 键，在 cmmand 组合快捷键 keyup 只执行一次的问题


    if (event.key && event.key.toLowerCase() === 'meta') {
      _downKeys.splice(0, _downKeys.length);
    } // 修饰键 shiftKey altKey ctrlKey (command||metaKey) 清除


    if (key === 93 || key === 224) key = 91;

    if (key in _mods) {
      _mods[key] = false; // 将修饰键重置为false

      for (var k in _modifier) {
        if (_modifier[k] === key) hotkeys[k] = false;
      }
    }
  }

  function unbind(keysInfo) {
    // unbind(), unbind all keys
    if (!keysInfo) {
      Object.keys(_handlers).forEach(function (key) {
        return delete _handlers[key];
      });
    } else if (Array.isArray(keysInfo)) {
      // support like : unbind([{key: 'ctrl+a', scope: 's1'}, {key: 'ctrl-a', scope: 's2', splitKey: '-'}])
      keysInfo.forEach(function (info) {
        if (info.key) eachUnbind(info);
      });
    } else if (typeof keysInfo === 'object') {
      // support like unbind({key: 'ctrl+a, ctrl+b', scope:'abc'})
      if (keysInfo.key) eachUnbind(keysInfo);
    } else if (typeof keysInfo === 'string') {
      for (var _len = arguments.length, args = new Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
        args[_key - 1] = arguments[_key];
      }

      // support old method
      // eslint-disable-line
      var scope = args[0],
          method = args[1];

      if (typeof scope === 'function') {
        method = scope;
        scope = '';
      }

      eachUnbind({
        key: keysInfo,
        scope: scope,
        method: method,
        splitKey: '+'
      });
    }
  } // 解除绑定某个范围的快捷键


  var eachUnbind = function eachUnbind(_ref) {
    var key = _ref.key,
        scope = _ref.scope,
        method = _ref.method,
        _ref$splitKey = _ref.splitKey,
        splitKey = _ref$splitKey === void 0 ? '+' : _ref$splitKey;
    var multipleKeys = getKeys(key);
    multipleKeys.forEach(function (originKey) {
      var unbindKeys = originKey.split(splitKey);
      var len = unbindKeys.length;
      var lastKey = unbindKeys[len - 1];
      var keyCode = lastKey === '*' ? '*' : code(lastKey);
      if (!_handlers[keyCode]) return; // 判断是否传入范围，没有就获取范围

      if (!scope) scope = getScope();
      var mods = len > 1 ? getMods(_modifier, unbindKeys) : [];
      _handlers[keyCode] = _handlers[keyCode].map(function (record) {
        // 通过函数判断，是否解除绑定，函数相等直接返回
        var isMatchingMethod = method ? record.method === method : true;

        if (isMatchingMethod && record.scope === scope && compareArray(record.mods, mods)) {
          return {};
        }

        return record;
      });
    });
  }; // 对监听对应快捷键的回调函数进行处理


  function eventHandler(event, handler, scope) {
    var modifiersMatch; // 看它是否在当前范围

    if (handler.scope === scope || handler.scope === 'all') {
      // 检查是否匹配修饰符（如果有返回true）
      modifiersMatch = handler.mods.length > 0;

      for (var y in _mods) {
        if (Object.prototype.hasOwnProperty.call(_mods, y)) {
          if (!_mods[y] && handler.mods.indexOf(+y) > -1 || _mods[y] && handler.mods.indexOf(+y) === -1) {
            modifiersMatch = false;
          }
        }
      } // 调用处理程序，如果是修饰键不做处理


      if (handler.mods.length === 0 && !_mods[16] && !_mods[18] && !_mods[17] && !_mods[91] || modifiersMatch || handler.shortcut === '*') {
        if (handler.method(event, handler) === false) {
          if (event.preventDefault) event.preventDefault();else event.returnValue = false;
          if (event.stopPropagation) event.stopPropagation();
          if (event.cancelBubble) event.cancelBubble = true;
        }
      }
    }
  } // 处理keydown事件


  function dispatch(event) {
    var asterisk = _handlers['*'];
    var key = event.keyCode || event.which || event.charCode; // 表单控件过滤 默认表单控件不触发快捷键

    if (!hotkeys.filter.call(this, event)) return; // Gecko(Firefox)的command键值224，在Webkit(Chrome)中保持一致
    // Webkit左右 command 键值不一样

    if (key === 93 || key === 224) key = 91;
    /**
     * Collect bound keys
     * If an Input Method Editor is processing key input and the event is keydown, return 229.
     * https://stackoverflow.com/questions/25043934/is-it-ok-to-ignore-keydown-events-with-keycode-229
     * http://lists.w3.org/Archives/Public/www-dom/2010JulSep/att-0182/keyCode-spec.html
     */

    if (_downKeys.indexOf(key) === -1 && key !== 229) _downKeys.push(key);
    /**
     * Jest test cases are required.
     * ===============================
     */

    ['ctrlKey', 'altKey', 'shiftKey', 'metaKey'].forEach(function (keyName) {
      var keyNum = modifierMap[keyName];

      if (event[keyName] && _downKeys.indexOf(keyNum) === -1) {
        _downKeys.push(keyNum);
      } else if (!event[keyName] && _downKeys.indexOf(keyNum) > -1) {
        _downKeys.splice(_downKeys.indexOf(keyNum), 1);
      } else if (keyName === 'metaKey' && event[keyName] && _downKeys.length === 3) {
        /**
         * Fix if Command is pressed:
         * ===============================
         */
        if (!(event.ctrlKey || event.shiftKey || event.altKey)) {
          _downKeys = _downKeys.slice(_downKeys.indexOf(keyNum));
        }
      }
    });
    /**
     * -------------------------------
     */

    if (key in _mods) {
      _mods[key] = true; // 将特殊字符的key注册到 hotkeys 上

      for (var k in _modifier) {
        if (_modifier[k] === key) hotkeys[k] = true;
      }

      if (!asterisk) return;
    } // 将 modifierMap 里面的修饰键绑定到 event 中


    for (var e in _mods) {
      if (Object.prototype.hasOwnProperty.call(_mods, e)) {
        _mods[e] = event[modifierMap[e]];
      }
    }
    /**
     * https://github.com/jaywcjlove/hotkeys/pull/129
     * This solves the issue in Firefox on Windows where hotkeys corresponding to special characters would not trigger.
     * An example of this is ctrl+alt+m on a Swedish keyboard which is used to type μ.
     * Browser support: https://caniuse.com/#feat=keyboardevent-getmodifierstate
     */


    if (event.getModifierState && !(event.altKey && !event.ctrlKey) && event.getModifierState('AltGraph')) {
      if (_downKeys.indexOf(17) === -1) {
        _downKeys.push(17);
      }

      if (_downKeys.indexOf(18) === -1) {
        _downKeys.push(18);
      }

      _mods[17] = true;
      _mods[18] = true;
    } // 获取范围 默认为 `all`


    var scope = getScope(); // 对任何快捷键都需要做的处理

    if (asterisk) {
      for (var i = 0; i < asterisk.length; i++) {
        if (asterisk[i].scope === scope && (event.type === 'keydown' && asterisk[i].keydown || event.type === 'keyup' && asterisk[i].keyup)) {
          eventHandler(event, asterisk[i], scope);
        }
      }
    } // key 不在 _handlers 中返回


    if (!(key in _handlers)) return;

    for (var _i = 0; _i < _handlers[key].length; _i++) {
      if (event.type === 'keydown' && _handlers[key][_i].keydown || event.type === 'keyup' && _handlers[key][_i].keyup) {
        if (_handlers[key][_i].key) {
          var record = _handlers[key][_i];
          var splitKey = record.splitKey;
          var keyShortcut = record.key.split(splitKey);
          var _downKeysCurrent = []; // 记录当前按键键值

          for (var a = 0; a < keyShortcut.length; a++) {
            _downKeysCurrent.push(code(keyShortcut[a]));
          }

          if (_downKeysCurrent.sort().join('') === _downKeys.sort().join('')) {
            // 找到处理内容
            eventHandler(event, record, scope);
          }
        }
      }
    }
  } // 判断 element 是否已经绑定事件


  function isElementBind(element) {
    return elementHasBindEvent.indexOf(element) > -1;
  }

  function hotkeys(key, option, method) {
    _downKeys = [];
    var keys = getKeys(key); // 需要处理的快捷键列表

    var mods = [];
    var scope = 'all'; // scope默认为all，所有范围都有效

    var element = document; // 快捷键事件绑定节点

    var i = 0;
    var keyup = false;
    var keydown = true;
    var splitKey = '+'; // 对为设定范围的判断

    if (method === undefined && typeof option === 'function') {
      method = option;
    }

    if (Object.prototype.toString.call(option) === '[object Object]') {
      if (option.scope) scope = option.scope; // eslint-disable-line

      if (option.element) element = option.element; // eslint-disable-line

      if (option.keyup) keyup = option.keyup; // eslint-disable-line

      if (option.keydown !== undefined) keydown = option.keydown; // eslint-disable-line

      if (typeof option.splitKey === 'string') splitKey = option.splitKey; // eslint-disable-line
    }

    if (typeof option === 'string') scope = option; // 对于每个快捷键进行处理

    for (; i < keys.length; i++) {
      key = keys[i].split(splitKey); // 按键列表

      mods = []; // 如果是组合快捷键取得组合快捷键

      if (key.length > 1) mods = getMods(_modifier, key); // 将非修饰键转化为键码

      key = key[key.length - 1];
      key = key === '*' ? '*' : code(key); // *表示匹配所有快捷键
      // 判断key是否在_handlers中，不在就赋一个空数组

      if (!(key in _handlers)) _handlers[key] = [];

      _handlers[key].push({
        keyup: keyup,
        keydown: keydown,
        scope: scope,
        mods: mods,
        shortcut: keys[i],
        method: method,
        key: keys[i],
        splitKey: splitKey
      });
    } // 在全局document上设置快捷键


    if (typeof element !== 'undefined' && !isElementBind(element) && window) {
      elementHasBindEvent.push(element);
      addEvent(element, 'keydown', function (e) {
        dispatch(e);
      });
      addEvent(window, 'focus', function () {
        _downKeys = [];
      });
      addEvent(element, 'keyup', function (e) {
        dispatch(e);
        clearModifier(e);
      });
    }
  }

  var _api = {
    setScope: setScope,
    getScope: getScope,
    deleteScope: deleteScope,
    getPressedKeyCodes: getPressedKeyCodes,
    isPressed: isPressed,
    filter: filter,
    unbind: unbind
  };

  for (var a in _api) {
    if (Object.prototype.hasOwnProperty.call(_api, a)) {
      hotkeys[a] = _api[a];
    }
  }

  if (typeof window !== 'undefined') {
    var _hotkeys = window.hotkeys;

    hotkeys.noConflict = function (deep) {
      if (deep && window.hotkeys === hotkeys) {
        window.hotkeys = _hotkeys;
      }

      return hotkeys;
    };

    window.hotkeys = hotkeys;
  }

  return hotkeys;

})));
