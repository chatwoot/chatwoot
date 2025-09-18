'use strict';

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

Object.defineProperty(exports, '__esModule', {
  value: true
});

var prosemirrorState = require('prosemirror-state');

var prosemirrorTransform = require('prosemirror-transform');

function dropCursor() {
  var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
  return new prosemirrorState.Plugin({
    view: function view(editorView) {
      return new DropCursorView(editorView, options);
    }
  });
}

var DropCursorView = function () {
  function DropCursorView(editorView, options) {
    var _this = this;

    _classCallCheck(this, DropCursorView);

    var _a;

    this.editorView = editorView;
    this.cursorPos = null;
    this.element = null;
    this.timeout = -1;
    this.width = (_a = options.width) !== null && _a !== void 0 ? _a : 1;
    this.color = options.color === false ? undefined : options.color || "black";
    this["class"] = options["class"];
    this.handlers = ["dragover", "dragend", "drop", "dragleave"].map(function (name) {
      var handler = function handler(e) {
        _this[name](e);
      };

      editorView.dom.addEventListener(name, handler);
      return {
        name: name,
        handler: handler
      };
    });
  }

  _createClass(DropCursorView, [{
    key: "destroy",
    value: function destroy() {
      var _this2 = this;

      this.handlers.forEach(function (_ref) {
        var name = _ref.name,
            handler = _ref.handler;
        return _this2.editorView.dom.removeEventListener(name, handler);
      });
    }
  }, {
    key: "update",
    value: function update(editorView, prevState) {
      if (this.cursorPos != null && prevState.doc != editorView.state.doc) {
        if (this.cursorPos > editorView.state.doc.content.size) this.setCursor(null);else this.updateOverlay();
      }
    }
  }, {
    key: "setCursor",
    value: function setCursor(pos) {
      if (pos == this.cursorPos) return;
      this.cursorPos = pos;

      if (pos == null) {
        this.element.parentNode.removeChild(this.element);
        this.element = null;
      } else {
        this.updateOverlay();
      }
    }
  }, {
    key: "updateOverlay",
    value: function updateOverlay() {
      var $pos = this.editorView.state.doc.resolve(this.cursorPos);
      var isBlock = !$pos.parent.inlineContent,
          rect;

      if (isBlock) {
        var before = $pos.nodeBefore,
            after = $pos.nodeAfter;

        if (before || after) {
          var node = this.editorView.nodeDOM(this.cursorPos - (before ? before.nodeSize : 0));

          if (node) {
            var nodeRect = node.getBoundingClientRect();
            var top = before ? nodeRect.bottom : nodeRect.top;
            if (before && after) top = (top + this.editorView.nodeDOM(this.cursorPos).getBoundingClientRect().top) / 2;
            rect = {
              left: nodeRect.left,
              right: nodeRect.right,
              top: top - this.width / 2,
              bottom: top + this.width / 2
            };
          }
        }
      }

      if (!rect) {
        var coords = this.editorView.coordsAtPos(this.cursorPos);
        rect = {
          left: coords.left - this.width / 2,
          right: coords.left + this.width / 2,
          top: coords.top,
          bottom: coords.bottom
        };
      }

      var parent = this.editorView.dom.offsetParent;

      if (!this.element) {
        this.element = parent.appendChild(document.createElement("div"));
        if (this["class"]) this.element.className = this["class"];
        this.element.style.cssText = "position: absolute; z-index: 50; pointer-events: none;";

        if (this.color) {
          this.element.style.backgroundColor = this.color;
        }
      }

      this.element.classList.toggle("prosemirror-dropcursor-block", isBlock);
      this.element.classList.toggle("prosemirror-dropcursor-inline", !isBlock);
      var parentLeft, parentTop;

      if (!parent || parent == document.body && getComputedStyle(parent).position == "static") {
        parentLeft = -pageXOffset;
        parentTop = -pageYOffset;
      } else {
        var _rect = parent.getBoundingClientRect();

        parentLeft = _rect.left - parent.scrollLeft;
        parentTop = _rect.top - parent.scrollTop;
      }

      this.element.style.left = rect.left - parentLeft + "px";
      this.element.style.top = rect.top - parentTop + "px";
      this.element.style.width = rect.right - rect.left + "px";
      this.element.style.height = rect.bottom - rect.top + "px";
    }
  }, {
    key: "scheduleRemoval",
    value: function scheduleRemoval(timeout) {
      var _this3 = this;

      clearTimeout(this.timeout);
      this.timeout = setTimeout(function () {
        return _this3.setCursor(null);
      }, timeout);
    }
  }, {
    key: "dragover",
    value: function dragover(event) {
      if (!this.editorView.editable) return;
      var pos = this.editorView.posAtCoords({
        left: event.clientX,
        top: event.clientY
      });
      var node = pos && pos.inside >= 0 && this.editorView.state.doc.nodeAt(pos.inside);
      var disableDropCursor = node && node.type.spec.disableDropCursor;
      var disabled = typeof disableDropCursor == "function" ? disableDropCursor(this.editorView, pos, event) : disableDropCursor;

      if (pos && !disabled) {
        var target = pos.pos;

        if (this.editorView.dragging && this.editorView.dragging.slice) {
          var point = prosemirrorTransform.dropPoint(this.editorView.state.doc, target, this.editorView.dragging.slice);
          if (point != null) target = point;
        }

        this.setCursor(target);
        this.scheduleRemoval(5000);
      }
    }
  }, {
    key: "dragend",
    value: function dragend() {
      this.scheduleRemoval(20);
    }
  }, {
    key: "drop",
    value: function drop() {
      this.scheduleRemoval(20);
    }
  }, {
    key: "dragleave",
    value: function dragleave(event) {
      if (event.target == this.editorView.dom || !this.editorView.dom.contains(event.relatedTarget)) this.setCursor(null);
    }
  }]);

  return DropCursorView;
}();

exports.dropCursor = dropCursor;
