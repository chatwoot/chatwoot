import "core-js/modules/es.array.from.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.array.includes.js";
import global from 'global';
var document = global.document; // https://html.spec.whatwg.org/multipage/scripting.html

var runScriptTypes = ['application/javascript', 'application/ecmascript', 'application/x-ecmascript', 'application/x-javascript', 'text/ecmascript', 'text/javascript', 'text/javascript1.0', 'text/javascript1.1', 'text/javascript1.2', 'text/javascript1.3', 'text/javascript1.4', 'text/javascript1.5', 'text/jscript', 'text/livescript', 'text/x-ecmascript', 'text/x-javascript', // Support modern javascript
'module'];
var SCRIPT = 'script';
var SCRIPTS_ROOT_ID = 'scripts-root'; // trigger DOMContentLoaded

export function simulateDOMContentLoaded() {
  var DOMContentLoadedEvent = document.createEvent('Event');
  DOMContentLoadedEvent.initEvent('DOMContentLoaded', true, true);
  document.dispatchEvent(DOMContentLoadedEvent);
}

function insertScript($script, callback, $scriptRoot) {
  var scriptEl = document.createElement('script');
  scriptEl.type = $script.type === 'module' ? 'module' : 'text/javascript';

  if ($script.src) {
    scriptEl.onload = callback;
    scriptEl.onerror = callback;
    scriptEl.src = $script.src;
  } else {
    scriptEl.textContent = $script.innerText;
  } // re-insert the script tag so it executes.


  if ($scriptRoot) $scriptRoot.appendChild(scriptEl);else document.head.appendChild(scriptEl); // clean-up

  $script.parentNode.removeChild($script); // run the callback immediately for inline scripts

  if (!$script.src) callback();
} // runs an array of async functions in sequential order

/* eslint-disable no-param-reassign, no-plusplus */


function insertScriptsSequentially(scriptsToExecute, callback) {
  var index = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 0;
  scriptsToExecute[index](function () {
    index++;

    if (index === scriptsToExecute.length) {
      callback();
    } else {
      insertScriptsSequentially(scriptsToExecute, callback, index);
    }
  });
}

export function simulatePageLoad($container) {
  var $scriptsRoot = document.getElementById(SCRIPTS_ROOT_ID);

  if (!$scriptsRoot) {
    $scriptsRoot = document.createElement('div');
    $scriptsRoot.id = SCRIPTS_ROOT_ID;
    document.body.appendChild($scriptsRoot);
  } else {
    $scriptsRoot.innerHTML = '';
  }

  var $scripts = Array.from($container.querySelectorAll(SCRIPT));

  if ($scripts.length) {
    var scriptsToExecute = [];
    $scripts.forEach(function ($script) {
      var typeAttr = $script.getAttribute('type'); // only run script tags without the type attribute
      // or with a javascript mime attribute value from the list

      if (!typeAttr || runScriptTypes.includes(typeAttr)) {
        scriptsToExecute.push(function (callback) {
          return insertScript($script, callback, $scriptsRoot);
        });
      }
    }); // insert the script tags sequentially
    // to preserve execution order

    if (scriptsToExecute.length) {
      insertScriptsSequentially(scriptsToExecute, simulateDOMContentLoaded, undefined);
    }
  } else {
    simulateDOMContentLoaded();
  }
}