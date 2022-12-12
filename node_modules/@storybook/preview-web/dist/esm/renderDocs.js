import "regenerator-runtime/runtime.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

import React from 'react';
import ReactDOM from 'react-dom';
import { NoDocs } from './NoDocs';
export function renderDocs(story, docsContext, element, callback) {
  return renderDocsAsync(story, docsContext, element).then(callback);
}

function renderDocsAsync(_x, _x2, _x3) {
  return _renderDocsAsync.apply(this, arguments);
}

function _renderDocsAsync() {
  _renderDocsAsync = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(story, docsContext, element) {
    var _docs$getContainer, _docs$getPage;

    var docs, DocsContainer, Page, docsElement;
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            docs = story.parameters.docs;

            if (!((docs !== null && docs !== void 0 && docs.getPage || docs !== null && docs !== void 0 && docs.page) && !(docs !== null && docs !== void 0 && docs.getContainer || docs !== null && docs !== void 0 && docs.container))) {
              _context.next = 3;
              break;
            }

            throw new Error('No `docs.container` set, did you run `addon-docs/preset`?');

          case 3:
            _context.t1 = docs.container;

            if (_context.t1) {
              _context.next = 8;
              break;
            }

            _context.next = 7;
            return (_docs$getContainer = docs.getContainer) === null || _docs$getContainer === void 0 ? void 0 : _docs$getContainer.call(docs);

          case 7:
            _context.t1 = _context.sent;

          case 8:
            _context.t0 = _context.t1;

            if (_context.t0) {
              _context.next = 11;
              break;
            }

            _context.t0 = function (_ref) {
              var children = _ref.children;
              return /*#__PURE__*/React.createElement(React.Fragment, null, children);
            };

          case 11:
            DocsContainer = _context.t0;
            _context.t3 = docs.page;

            if (_context.t3) {
              _context.next = 17;
              break;
            }

            _context.next = 16;
            return (_docs$getPage = docs.getPage) === null || _docs$getPage === void 0 ? void 0 : _docs$getPage.call(docs);

          case 16:
            _context.t3 = _context.sent;

          case 17:
            _context.t2 = _context.t3;

            if (_context.t2) {
              _context.next = 20;
              break;
            }

            _context.t2 = NoDocs;

          case 20:
            Page = _context.t2;
            // Use `componentId` as a key so that we force a re-render every time
            // we switch components
            docsElement = /*#__PURE__*/React.createElement(DocsContainer, {
              key: story.componentId,
              context: docsContext
            }, /*#__PURE__*/React.createElement(Page, null));
            _context.next = 24;
            return new Promise(function (resolve) {
              ReactDOM.render(docsElement, element, resolve);
            });

          case 24:
          case "end":
            return _context.stop();
        }
      }
    }, _callee);
  }));
  return _renderDocsAsync.apply(this, arguments);
}

export function unmountDocs(element) {
  ReactDOM.unmountComponentAtNode(element);
}