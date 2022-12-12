/**
 * Copyright (c) 2017 ESHA Research
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Declarative, persistent DOM content.
 *
 *   <input store name="whatever">
 *   <div store="somekey" store-area="session" contenteditable>Some content</div>
 *
 * Status: BETA - uses store, doesn't extend it, deserves standalone project
 */
;(function(document, store, _, Array) {

    // expose internal functions on store._.dom for extensibility
    var DOM = _.dom = function() {
        var nodes = document.querySelectorAll(DOM.selector),
            array = Array.prototype.slice.call(nodes);
        for (var i=0; i<array.length; i++) {
            DOM.node(array[i], i);
        }
        return array;
    };
    DOM.selector = '[store],[store-area]';
    DOM.event = 'input';// beforeunload is tempting
    DOM.node = function(node, i) {
        var key = DOM.key(node, i),
            area = DOM.area(node),
            value = area(key);
        if (value == null) {
            value = DOM.get(node);
        } else {
            DOM.set(node, value);
        }
        if (!node.storeListener) {
            node.addEventListener(DOM.event, function() {
                area(key, DOM.get(node));
            });
            node.storeListener = true;
        }
    };
    DOM.area = function(node) {
        return store[node.getAttribute('store-area') || 'local'];
    };
    // prefer store attribute value, then name attribute, use nodeName+index as last resort
    DOM.key = function(node, i) {
        return node.getAttribute('store') ||
            node.getAttribute('name') || 
            ('dom.'+node.nodeName.toLowerCase() + (i||''));
    };
    // both get and set should prefer value property to innerHTML
    DOM.get = function(node) {
        return node.value || node.innerHTML;
    };
    DOM.set = function(node, value) {
        if ('value' in node) {
            node.value = value;
        } else {
            node.innerHTML = typeof value === "string" ? value : _.stringify(value);
        }
    };

    // initialize
    document.addEventListener('DOMContentLoaded', DOM);

})(document, window.store, window.store._, Array);
