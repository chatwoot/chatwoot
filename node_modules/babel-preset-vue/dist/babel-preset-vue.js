(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
	typeof define === 'function' && define.amd ? define(factory) :
	(global.PresetVue = factory());
}(this, (function () { 'use strict';

	function unwrapExports (x) {
		return x && x.__esModule && Object.prototype.hasOwnProperty.call(x, 'default') ? x['default'] : x;
	}

	function createCommonjsModule(fn, module) {
		return module = { exports: {} }, fn(module, module.exports), module.exports;
	}

	var ast = createCommonjsModule(function (module) {
	/*
	  Copyright (C) 2013 Yusuke Suzuki <utatane.tea@gmail.com>

	  Redistribution and use in source and binary forms, with or without
	  modification, are permitted provided that the following conditions are met:

	    * Redistributions of source code must retain the above copyright
	      notice, this list of conditions and the following disclaimer.
	    * Redistributions in binary form must reproduce the above copyright
	      notice, this list of conditions and the following disclaimer in the
	      documentation and/or other materials provided with the distribution.

	  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS'
	  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	  ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
	  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
	  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
	  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
	*/

	(function () {

	    function isExpression(node) {
	        if (node == null) { return false; }
	        switch (node.type) {
	            case 'ArrayExpression':
	            case 'AssignmentExpression':
	            case 'BinaryExpression':
	            case 'CallExpression':
	            case 'ConditionalExpression':
	            case 'FunctionExpression':
	            case 'Identifier':
	            case 'Literal':
	            case 'LogicalExpression':
	            case 'MemberExpression':
	            case 'NewExpression':
	            case 'ObjectExpression':
	            case 'SequenceExpression':
	            case 'ThisExpression':
	            case 'UnaryExpression':
	            case 'UpdateExpression':
	                return true;
	        }
	        return false;
	    }

	    function isIterationStatement(node) {
	        if (node == null) { return false; }
	        switch (node.type) {
	            case 'DoWhileStatement':
	            case 'ForInStatement':
	            case 'ForStatement':
	            case 'WhileStatement':
	                return true;
	        }
	        return false;
	    }

	    function isStatement(node) {
	        if (node == null) { return false; }
	        switch (node.type) {
	            case 'BlockStatement':
	            case 'BreakStatement':
	            case 'ContinueStatement':
	            case 'DebuggerStatement':
	            case 'DoWhileStatement':
	            case 'EmptyStatement':
	            case 'ExpressionStatement':
	            case 'ForInStatement':
	            case 'ForStatement':
	            case 'IfStatement':
	            case 'LabeledStatement':
	            case 'ReturnStatement':
	            case 'SwitchStatement':
	            case 'ThrowStatement':
	            case 'TryStatement':
	            case 'VariableDeclaration':
	            case 'WhileStatement':
	            case 'WithStatement':
	                return true;
	        }
	        return false;
	    }

	    function isSourceElement(node) {
	      return isStatement(node) || node != null && node.type === 'FunctionDeclaration';
	    }

	    function trailingStatement(node) {
	        switch (node.type) {
	        case 'IfStatement':
	            if (node.alternate != null) {
	                return node.alternate;
	            }
	            return node.consequent;

	        case 'LabeledStatement':
	        case 'ForStatement':
	        case 'ForInStatement':
	        case 'WhileStatement':
	        case 'WithStatement':
	            return node.body;
	        }
	        return null;
	    }

	    function isProblematicIfStatement(node) {
	        var current;

	        if (node.type !== 'IfStatement') {
	            return false;
	        }
	        if (node.alternate == null) {
	            return false;
	        }
	        current = node.consequent;
	        do {
	            if (current.type === 'IfStatement') {
	                if (current.alternate == null)  {
	                    return true;
	                }
	            }
	            current = trailingStatement(current);
	        } while (current);

	        return false;
	    }

	    module.exports = {
	        isExpression: isExpression,
	        isStatement: isStatement,
	        isIterationStatement: isIterationStatement,
	        isSourceElement: isSourceElement,
	        isProblematicIfStatement: isProblematicIfStatement,

	        trailingStatement: trailingStatement
	    };
	}());
	/* vim: set sw=4 ts=4 et tw=80 : */
	});
	var ast_1 = ast.isExpression;
	var ast_2 = ast.isStatement;
	var ast_3 = ast.isIterationStatement;
	var ast_4 = ast.isSourceElement;
	var ast_5 = ast.isProblematicIfStatement;
	var ast_6 = ast.trailingStatement;

	var code = createCommonjsModule(function (module) {
	/*
	  Copyright (C) 2013-2014 Yusuke Suzuki <utatane.tea@gmail.com>
	  Copyright (C) 2014 Ivan Nikulin <ifaaan@gmail.com>

	  Redistribution and use in source and binary forms, with or without
	  modification, are permitted provided that the following conditions are met:

	    * Redistributions of source code must retain the above copyright
	      notice, this list of conditions and the following disclaimer.
	    * Redistributions in binary form must reproduce the above copyright
	      notice, this list of conditions and the following disclaimer in the
	      documentation and/or other materials provided with the distribution.

	  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	  ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
	  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
	  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
	  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
	*/

	(function () {

	    var ES6Regex, ES5Regex, NON_ASCII_WHITESPACES, IDENTIFIER_START, IDENTIFIER_PART, ch;

	    // See `tools/generate-identifier-regex.js`.
	    ES5Regex = {
	        // ECMAScript 5.1/Unicode v7.0.0 NonAsciiIdentifierStart:
	        NonAsciiIdentifierStart: /[\xAA\xB5\xBA\xC0-\xD6\xD8-\xF6\xF8-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0370-\u0374\u0376\u0377\u037A-\u037D\u037F\u0386\u0388-\u038A\u038C\u038E-\u03A1\u03A3-\u03F5\u03F7-\u0481\u048A-\u052F\u0531-\u0556\u0559\u0561-\u0587\u05D0-\u05EA\u05F0-\u05F2\u0620-\u064A\u066E\u066F\u0671-\u06D3\u06D5\u06E5\u06E6\u06EE\u06EF\u06FA-\u06FC\u06FF\u0710\u0712-\u072F\u074D-\u07A5\u07B1\u07CA-\u07EA\u07F4\u07F5\u07FA\u0800-\u0815\u081A\u0824\u0828\u0840-\u0858\u08A0-\u08B2\u0904-\u0939\u093D\u0950\u0958-\u0961\u0971-\u0980\u0985-\u098C\u098F\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BD\u09CE\u09DC\u09DD\u09DF-\u09E1\u09F0\u09F1\u0A05-\u0A0A\u0A0F\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32\u0A33\u0A35\u0A36\u0A38\u0A39\u0A59-\u0A5C\u0A5E\u0A72-\u0A74\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2\u0AB3\u0AB5-\u0AB9\u0ABD\u0AD0\u0AE0\u0AE1\u0B05-\u0B0C\u0B0F\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32\u0B33\u0B35-\u0B39\u0B3D\u0B5C\u0B5D\u0B5F-\u0B61\u0B71\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99\u0B9A\u0B9C\u0B9E\u0B9F\u0BA3\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BD0\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D\u0C58\u0C59\u0C60\u0C61\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBD\u0CDE\u0CE0\u0CE1\u0CF1\u0CF2\u0D05-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D\u0D4E\u0D60\u0D61\u0D7A-\u0D7F\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0E01-\u0E30\u0E32\u0E33\u0E40-\u0E46\u0E81\u0E82\u0E84\u0E87\u0E88\u0E8A\u0E8D\u0E94-\u0E97\u0E99-\u0E9F\u0EA1-\u0EA3\u0EA5\u0EA7\u0EAA\u0EAB\u0EAD-\u0EB0\u0EB2\u0EB3\u0EBD\u0EC0-\u0EC4\u0EC6\u0EDC-\u0EDF\u0F00\u0F40-\u0F47\u0F49-\u0F6C\u0F88-\u0F8C\u1000-\u102A\u103F\u1050-\u1055\u105A-\u105D\u1061\u1065\u1066\u106E-\u1070\u1075-\u1081\u108E\u10A0-\u10C5\u10C7\u10CD\u10D0-\u10FA\u10FC-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u1380-\u138F\u13A0-\u13F4\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16EE-\u16F8\u1700-\u170C\u170E-\u1711\u1720-\u1731\u1740-\u1751\u1760-\u176C\u176E-\u1770\u1780-\u17B3\u17D7\u17DC\u1820-\u1877\u1880-\u18A8\u18AA\u18B0-\u18F5\u1900-\u191E\u1950-\u196D\u1970-\u1974\u1980-\u19AB\u19C1-\u19C7\u1A00-\u1A16\u1A20-\u1A54\u1AA7\u1B05-\u1B33\u1B45-\u1B4B\u1B83-\u1BA0\u1BAE\u1BAF\u1BBA-\u1BE5\u1C00-\u1C23\u1C4D-\u1C4F\u1C5A-\u1C7D\u1CE9-\u1CEC\u1CEE-\u1CF1\u1CF5\u1CF6\u1D00-\u1DBF\u1E00-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FBC\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FCC\u1FD0-\u1FD3\u1FD6-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FF4\u1FF6-\u1FFC\u2071\u207F\u2090-\u209C\u2102\u2107\u210A-\u2113\u2115\u2119-\u211D\u2124\u2126\u2128\u212A-\u212D\u212F-\u2139\u213C-\u213F\u2145-\u2149\u214E\u2160-\u2188\u2C00-\u2C2E\u2C30-\u2C5E\u2C60-\u2CE4\u2CEB-\u2CEE\u2CF2\u2CF3\u2D00-\u2D25\u2D27\u2D2D\u2D30-\u2D67\u2D6F\u2D80-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u2E2F\u3005-\u3007\u3021-\u3029\u3031-\u3035\u3038-\u303C\u3041-\u3096\u309D-\u309F\u30A1-\u30FA\u30FC-\u30FF\u3105-\u312D\u3131-\u318E\u31A0-\u31BA\u31F0-\u31FF\u3400-\u4DB5\u4E00-\u9FCC\uA000-\uA48C\uA4D0-\uA4FD\uA500-\uA60C\uA610-\uA61F\uA62A\uA62B\uA640-\uA66E\uA67F-\uA69D\uA6A0-\uA6EF\uA717-\uA71F\uA722-\uA788\uA78B-\uA78E\uA790-\uA7AD\uA7B0\uA7B1\uA7F7-\uA801\uA803-\uA805\uA807-\uA80A\uA80C-\uA822\uA840-\uA873\uA882-\uA8B3\uA8F2-\uA8F7\uA8FB\uA90A-\uA925\uA930-\uA946\uA960-\uA97C\uA984-\uA9B2\uA9CF\uA9E0-\uA9E4\uA9E6-\uA9EF\uA9FA-\uA9FE\uAA00-\uAA28\uAA40-\uAA42\uAA44-\uAA4B\uAA60-\uAA76\uAA7A\uAA7E-\uAAAF\uAAB1\uAAB5\uAAB6\uAAB9-\uAABD\uAAC0\uAAC2\uAADB-\uAADD\uAAE0-\uAAEA\uAAF2-\uAAF4\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uAB30-\uAB5A\uAB5C-\uAB5F\uAB64\uAB65\uABC0-\uABE2\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB00-\uFB06\uFB13-\uFB17\uFB1D\uFB1F-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40\uFB41\uFB43\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE70-\uFE74\uFE76-\uFEFC\uFF21-\uFF3A\uFF41-\uFF5A\uFF66-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC]/,
	        // ECMAScript 5.1/Unicode v7.0.0 NonAsciiIdentifierPart:
	        NonAsciiIdentifierPart: /[\xAA\xB5\xBA\xC0-\xD6\xD8-\xF6\xF8-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0300-\u0374\u0376\u0377\u037A-\u037D\u037F\u0386\u0388-\u038A\u038C\u038E-\u03A1\u03A3-\u03F5\u03F7-\u0481\u0483-\u0487\u048A-\u052F\u0531-\u0556\u0559\u0561-\u0587\u0591-\u05BD\u05BF\u05C1\u05C2\u05C4\u05C5\u05C7\u05D0-\u05EA\u05F0-\u05F2\u0610-\u061A\u0620-\u0669\u066E-\u06D3\u06D5-\u06DC\u06DF-\u06E8\u06EA-\u06FC\u06FF\u0710-\u074A\u074D-\u07B1\u07C0-\u07F5\u07FA\u0800-\u082D\u0840-\u085B\u08A0-\u08B2\u08E4-\u0963\u0966-\u096F\u0971-\u0983\u0985-\u098C\u098F\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BC-\u09C4\u09C7\u09C8\u09CB-\u09CE\u09D7\u09DC\u09DD\u09DF-\u09E3\u09E6-\u09F1\u0A01-\u0A03\u0A05-\u0A0A\u0A0F\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32\u0A33\u0A35\u0A36\u0A38\u0A39\u0A3C\u0A3E-\u0A42\u0A47\u0A48\u0A4B-\u0A4D\u0A51\u0A59-\u0A5C\u0A5E\u0A66-\u0A75\u0A81-\u0A83\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2\u0AB3\u0AB5-\u0AB9\u0ABC-\u0AC5\u0AC7-\u0AC9\u0ACB-\u0ACD\u0AD0\u0AE0-\u0AE3\u0AE6-\u0AEF\u0B01-\u0B03\u0B05-\u0B0C\u0B0F\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32\u0B33\u0B35-\u0B39\u0B3C-\u0B44\u0B47\u0B48\u0B4B-\u0B4D\u0B56\u0B57\u0B5C\u0B5D\u0B5F-\u0B63\u0B66-\u0B6F\u0B71\u0B82\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99\u0B9A\u0B9C\u0B9E\u0B9F\u0BA3\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BBE-\u0BC2\u0BC6-\u0BC8\u0BCA-\u0BCD\u0BD0\u0BD7\u0BE6-\u0BEF\u0C00-\u0C03\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D-\u0C44\u0C46-\u0C48\u0C4A-\u0C4D\u0C55\u0C56\u0C58\u0C59\u0C60-\u0C63\u0C66-\u0C6F\u0C81-\u0C83\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBC-\u0CC4\u0CC6-\u0CC8\u0CCA-\u0CCD\u0CD5\u0CD6\u0CDE\u0CE0-\u0CE3\u0CE6-\u0CEF\u0CF1\u0CF2\u0D01-\u0D03\u0D05-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D-\u0D44\u0D46-\u0D48\u0D4A-\u0D4E\u0D57\u0D60-\u0D63\u0D66-\u0D6F\u0D7A-\u0D7F\u0D82\u0D83\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0DCA\u0DCF-\u0DD4\u0DD6\u0DD8-\u0DDF\u0DE6-\u0DEF\u0DF2\u0DF3\u0E01-\u0E3A\u0E40-\u0E4E\u0E50-\u0E59\u0E81\u0E82\u0E84\u0E87\u0E88\u0E8A\u0E8D\u0E94-\u0E97\u0E99-\u0E9F\u0EA1-\u0EA3\u0EA5\u0EA7\u0EAA\u0EAB\u0EAD-\u0EB9\u0EBB-\u0EBD\u0EC0-\u0EC4\u0EC6\u0EC8-\u0ECD\u0ED0-\u0ED9\u0EDC-\u0EDF\u0F00\u0F18\u0F19\u0F20-\u0F29\u0F35\u0F37\u0F39\u0F3E-\u0F47\u0F49-\u0F6C\u0F71-\u0F84\u0F86-\u0F97\u0F99-\u0FBC\u0FC6\u1000-\u1049\u1050-\u109D\u10A0-\u10C5\u10C7\u10CD\u10D0-\u10FA\u10FC-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u135D-\u135F\u1380-\u138F\u13A0-\u13F4\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16EE-\u16F8\u1700-\u170C\u170E-\u1714\u1720-\u1734\u1740-\u1753\u1760-\u176C\u176E-\u1770\u1772\u1773\u1780-\u17D3\u17D7\u17DC\u17DD\u17E0-\u17E9\u180B-\u180D\u1810-\u1819\u1820-\u1877\u1880-\u18AA\u18B0-\u18F5\u1900-\u191E\u1920-\u192B\u1930-\u193B\u1946-\u196D\u1970-\u1974\u1980-\u19AB\u19B0-\u19C9\u19D0-\u19D9\u1A00-\u1A1B\u1A20-\u1A5E\u1A60-\u1A7C\u1A7F-\u1A89\u1A90-\u1A99\u1AA7\u1AB0-\u1ABD\u1B00-\u1B4B\u1B50-\u1B59\u1B6B-\u1B73\u1B80-\u1BF3\u1C00-\u1C37\u1C40-\u1C49\u1C4D-\u1C7D\u1CD0-\u1CD2\u1CD4-\u1CF6\u1CF8\u1CF9\u1D00-\u1DF5\u1DFC-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FBC\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FCC\u1FD0-\u1FD3\u1FD6-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FF4\u1FF6-\u1FFC\u200C\u200D\u203F\u2040\u2054\u2071\u207F\u2090-\u209C\u20D0-\u20DC\u20E1\u20E5-\u20F0\u2102\u2107\u210A-\u2113\u2115\u2119-\u211D\u2124\u2126\u2128\u212A-\u212D\u212F-\u2139\u213C-\u213F\u2145-\u2149\u214E\u2160-\u2188\u2C00-\u2C2E\u2C30-\u2C5E\u2C60-\u2CE4\u2CEB-\u2CF3\u2D00-\u2D25\u2D27\u2D2D\u2D30-\u2D67\u2D6F\u2D7F-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u2DE0-\u2DFF\u2E2F\u3005-\u3007\u3021-\u302F\u3031-\u3035\u3038-\u303C\u3041-\u3096\u3099\u309A\u309D-\u309F\u30A1-\u30FA\u30FC-\u30FF\u3105-\u312D\u3131-\u318E\u31A0-\u31BA\u31F0-\u31FF\u3400-\u4DB5\u4E00-\u9FCC\uA000-\uA48C\uA4D0-\uA4FD\uA500-\uA60C\uA610-\uA62B\uA640-\uA66F\uA674-\uA67D\uA67F-\uA69D\uA69F-\uA6F1\uA717-\uA71F\uA722-\uA788\uA78B-\uA78E\uA790-\uA7AD\uA7B0\uA7B1\uA7F7-\uA827\uA840-\uA873\uA880-\uA8C4\uA8D0-\uA8D9\uA8E0-\uA8F7\uA8FB\uA900-\uA92D\uA930-\uA953\uA960-\uA97C\uA980-\uA9C0\uA9CF-\uA9D9\uA9E0-\uA9FE\uAA00-\uAA36\uAA40-\uAA4D\uAA50-\uAA59\uAA60-\uAA76\uAA7A-\uAAC2\uAADB-\uAADD\uAAE0-\uAAEF\uAAF2-\uAAF6\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uAB30-\uAB5A\uAB5C-\uAB5F\uAB64\uAB65\uABC0-\uABEA\uABEC\uABED\uABF0-\uABF9\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB00-\uFB06\uFB13-\uFB17\uFB1D-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40\uFB41\uFB43\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE00-\uFE0F\uFE20-\uFE2D\uFE33\uFE34\uFE4D-\uFE4F\uFE70-\uFE74\uFE76-\uFEFC\uFF10-\uFF19\uFF21-\uFF3A\uFF3F\uFF41-\uFF5A\uFF66-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC]/
	    };

	    ES6Regex = {
	        // ECMAScript 6/Unicode v7.0.0 NonAsciiIdentifierStart:
	        NonAsciiIdentifierStart: /[\xAA\xB5\xBA\xC0-\xD6\xD8-\xF6\xF8-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0370-\u0374\u0376\u0377\u037A-\u037D\u037F\u0386\u0388-\u038A\u038C\u038E-\u03A1\u03A3-\u03F5\u03F7-\u0481\u048A-\u052F\u0531-\u0556\u0559\u0561-\u0587\u05D0-\u05EA\u05F0-\u05F2\u0620-\u064A\u066E\u066F\u0671-\u06D3\u06D5\u06E5\u06E6\u06EE\u06EF\u06FA-\u06FC\u06FF\u0710\u0712-\u072F\u074D-\u07A5\u07B1\u07CA-\u07EA\u07F4\u07F5\u07FA\u0800-\u0815\u081A\u0824\u0828\u0840-\u0858\u08A0-\u08B2\u0904-\u0939\u093D\u0950\u0958-\u0961\u0971-\u0980\u0985-\u098C\u098F\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BD\u09CE\u09DC\u09DD\u09DF-\u09E1\u09F0\u09F1\u0A05-\u0A0A\u0A0F\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32\u0A33\u0A35\u0A36\u0A38\u0A39\u0A59-\u0A5C\u0A5E\u0A72-\u0A74\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2\u0AB3\u0AB5-\u0AB9\u0ABD\u0AD0\u0AE0\u0AE1\u0B05-\u0B0C\u0B0F\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32\u0B33\u0B35-\u0B39\u0B3D\u0B5C\u0B5D\u0B5F-\u0B61\u0B71\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99\u0B9A\u0B9C\u0B9E\u0B9F\u0BA3\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BD0\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D\u0C58\u0C59\u0C60\u0C61\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBD\u0CDE\u0CE0\u0CE1\u0CF1\u0CF2\u0D05-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D\u0D4E\u0D60\u0D61\u0D7A-\u0D7F\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0E01-\u0E30\u0E32\u0E33\u0E40-\u0E46\u0E81\u0E82\u0E84\u0E87\u0E88\u0E8A\u0E8D\u0E94-\u0E97\u0E99-\u0E9F\u0EA1-\u0EA3\u0EA5\u0EA7\u0EAA\u0EAB\u0EAD-\u0EB0\u0EB2\u0EB3\u0EBD\u0EC0-\u0EC4\u0EC6\u0EDC-\u0EDF\u0F00\u0F40-\u0F47\u0F49-\u0F6C\u0F88-\u0F8C\u1000-\u102A\u103F\u1050-\u1055\u105A-\u105D\u1061\u1065\u1066\u106E-\u1070\u1075-\u1081\u108E\u10A0-\u10C5\u10C7\u10CD\u10D0-\u10FA\u10FC-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u1380-\u138F\u13A0-\u13F4\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16EE-\u16F8\u1700-\u170C\u170E-\u1711\u1720-\u1731\u1740-\u1751\u1760-\u176C\u176E-\u1770\u1780-\u17B3\u17D7\u17DC\u1820-\u1877\u1880-\u18A8\u18AA\u18B0-\u18F5\u1900-\u191E\u1950-\u196D\u1970-\u1974\u1980-\u19AB\u19C1-\u19C7\u1A00-\u1A16\u1A20-\u1A54\u1AA7\u1B05-\u1B33\u1B45-\u1B4B\u1B83-\u1BA0\u1BAE\u1BAF\u1BBA-\u1BE5\u1C00-\u1C23\u1C4D-\u1C4F\u1C5A-\u1C7D\u1CE9-\u1CEC\u1CEE-\u1CF1\u1CF5\u1CF6\u1D00-\u1DBF\u1E00-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FBC\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FCC\u1FD0-\u1FD3\u1FD6-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FF4\u1FF6-\u1FFC\u2071\u207F\u2090-\u209C\u2102\u2107\u210A-\u2113\u2115\u2118-\u211D\u2124\u2126\u2128\u212A-\u2139\u213C-\u213F\u2145-\u2149\u214E\u2160-\u2188\u2C00-\u2C2E\u2C30-\u2C5E\u2C60-\u2CE4\u2CEB-\u2CEE\u2CF2\u2CF3\u2D00-\u2D25\u2D27\u2D2D\u2D30-\u2D67\u2D6F\u2D80-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u3005-\u3007\u3021-\u3029\u3031-\u3035\u3038-\u303C\u3041-\u3096\u309B-\u309F\u30A1-\u30FA\u30FC-\u30FF\u3105-\u312D\u3131-\u318E\u31A0-\u31BA\u31F0-\u31FF\u3400-\u4DB5\u4E00-\u9FCC\uA000-\uA48C\uA4D0-\uA4FD\uA500-\uA60C\uA610-\uA61F\uA62A\uA62B\uA640-\uA66E\uA67F-\uA69D\uA6A0-\uA6EF\uA717-\uA71F\uA722-\uA788\uA78B-\uA78E\uA790-\uA7AD\uA7B0\uA7B1\uA7F7-\uA801\uA803-\uA805\uA807-\uA80A\uA80C-\uA822\uA840-\uA873\uA882-\uA8B3\uA8F2-\uA8F7\uA8FB\uA90A-\uA925\uA930-\uA946\uA960-\uA97C\uA984-\uA9B2\uA9CF\uA9E0-\uA9E4\uA9E6-\uA9EF\uA9FA-\uA9FE\uAA00-\uAA28\uAA40-\uAA42\uAA44-\uAA4B\uAA60-\uAA76\uAA7A\uAA7E-\uAAAF\uAAB1\uAAB5\uAAB6\uAAB9-\uAABD\uAAC0\uAAC2\uAADB-\uAADD\uAAE0-\uAAEA\uAAF2-\uAAF4\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uAB30-\uAB5A\uAB5C-\uAB5F\uAB64\uAB65\uABC0-\uABE2\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB00-\uFB06\uFB13-\uFB17\uFB1D\uFB1F-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40\uFB41\uFB43\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE70-\uFE74\uFE76-\uFEFC\uFF21-\uFF3A\uFF41-\uFF5A\uFF66-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC]|\uD800[\uDC00-\uDC0B\uDC0D-\uDC26\uDC28-\uDC3A\uDC3C\uDC3D\uDC3F-\uDC4D\uDC50-\uDC5D\uDC80-\uDCFA\uDD40-\uDD74\uDE80-\uDE9C\uDEA0-\uDED0\uDF00-\uDF1F\uDF30-\uDF4A\uDF50-\uDF75\uDF80-\uDF9D\uDFA0-\uDFC3\uDFC8-\uDFCF\uDFD1-\uDFD5]|\uD801[\uDC00-\uDC9D\uDD00-\uDD27\uDD30-\uDD63\uDE00-\uDF36\uDF40-\uDF55\uDF60-\uDF67]|\uD802[\uDC00-\uDC05\uDC08\uDC0A-\uDC35\uDC37\uDC38\uDC3C\uDC3F-\uDC55\uDC60-\uDC76\uDC80-\uDC9E\uDD00-\uDD15\uDD20-\uDD39\uDD80-\uDDB7\uDDBE\uDDBF\uDE00\uDE10-\uDE13\uDE15-\uDE17\uDE19-\uDE33\uDE60-\uDE7C\uDE80-\uDE9C\uDEC0-\uDEC7\uDEC9-\uDEE4\uDF00-\uDF35\uDF40-\uDF55\uDF60-\uDF72\uDF80-\uDF91]|\uD803[\uDC00-\uDC48]|\uD804[\uDC03-\uDC37\uDC83-\uDCAF\uDCD0-\uDCE8\uDD03-\uDD26\uDD50-\uDD72\uDD76\uDD83-\uDDB2\uDDC1-\uDDC4\uDDDA\uDE00-\uDE11\uDE13-\uDE2B\uDEB0-\uDEDE\uDF05-\uDF0C\uDF0F\uDF10\uDF13-\uDF28\uDF2A-\uDF30\uDF32\uDF33\uDF35-\uDF39\uDF3D\uDF5D-\uDF61]|\uD805[\uDC80-\uDCAF\uDCC4\uDCC5\uDCC7\uDD80-\uDDAE\uDE00-\uDE2F\uDE44\uDE80-\uDEAA]|\uD806[\uDCA0-\uDCDF\uDCFF\uDEC0-\uDEF8]|\uD808[\uDC00-\uDF98]|\uD809[\uDC00-\uDC6E]|[\uD80C\uD840-\uD868\uD86A-\uD86C][\uDC00-\uDFFF]|\uD80D[\uDC00-\uDC2E]|\uD81A[\uDC00-\uDE38\uDE40-\uDE5E\uDED0-\uDEED\uDF00-\uDF2F\uDF40-\uDF43\uDF63-\uDF77\uDF7D-\uDF8F]|\uD81B[\uDF00-\uDF44\uDF50\uDF93-\uDF9F]|\uD82C[\uDC00\uDC01]|\uD82F[\uDC00-\uDC6A\uDC70-\uDC7C\uDC80-\uDC88\uDC90-\uDC99]|\uD835[\uDC00-\uDC54\uDC56-\uDC9C\uDC9E\uDC9F\uDCA2\uDCA5\uDCA6\uDCA9-\uDCAC\uDCAE-\uDCB9\uDCBB\uDCBD-\uDCC3\uDCC5-\uDD05\uDD07-\uDD0A\uDD0D-\uDD14\uDD16-\uDD1C\uDD1E-\uDD39\uDD3B-\uDD3E\uDD40-\uDD44\uDD46\uDD4A-\uDD50\uDD52-\uDEA5\uDEA8-\uDEC0\uDEC2-\uDEDA\uDEDC-\uDEFA\uDEFC-\uDF14\uDF16-\uDF34\uDF36-\uDF4E\uDF50-\uDF6E\uDF70-\uDF88\uDF8A-\uDFA8\uDFAA-\uDFC2\uDFC4-\uDFCB]|\uD83A[\uDC00-\uDCC4]|\uD83B[\uDE00-\uDE03\uDE05-\uDE1F\uDE21\uDE22\uDE24\uDE27\uDE29-\uDE32\uDE34-\uDE37\uDE39\uDE3B\uDE42\uDE47\uDE49\uDE4B\uDE4D-\uDE4F\uDE51\uDE52\uDE54\uDE57\uDE59\uDE5B\uDE5D\uDE5F\uDE61\uDE62\uDE64\uDE67-\uDE6A\uDE6C-\uDE72\uDE74-\uDE77\uDE79-\uDE7C\uDE7E\uDE80-\uDE89\uDE8B-\uDE9B\uDEA1-\uDEA3\uDEA5-\uDEA9\uDEAB-\uDEBB]|\uD869[\uDC00-\uDED6\uDF00-\uDFFF]|\uD86D[\uDC00-\uDF34\uDF40-\uDFFF]|\uD86E[\uDC00-\uDC1D]|\uD87E[\uDC00-\uDE1D]/,
	        // ECMAScript 6/Unicode v7.0.0 NonAsciiIdentifierPart:
	        NonAsciiIdentifierPart: /[\xAA\xB5\xB7\xBA\xC0-\xD6\xD8-\xF6\xF8-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0300-\u0374\u0376\u0377\u037A-\u037D\u037F\u0386-\u038A\u038C\u038E-\u03A1\u03A3-\u03F5\u03F7-\u0481\u0483-\u0487\u048A-\u052F\u0531-\u0556\u0559\u0561-\u0587\u0591-\u05BD\u05BF\u05C1\u05C2\u05C4\u05C5\u05C7\u05D0-\u05EA\u05F0-\u05F2\u0610-\u061A\u0620-\u0669\u066E-\u06D3\u06D5-\u06DC\u06DF-\u06E8\u06EA-\u06FC\u06FF\u0710-\u074A\u074D-\u07B1\u07C0-\u07F5\u07FA\u0800-\u082D\u0840-\u085B\u08A0-\u08B2\u08E4-\u0963\u0966-\u096F\u0971-\u0983\u0985-\u098C\u098F\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BC-\u09C4\u09C7\u09C8\u09CB-\u09CE\u09D7\u09DC\u09DD\u09DF-\u09E3\u09E6-\u09F1\u0A01-\u0A03\u0A05-\u0A0A\u0A0F\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32\u0A33\u0A35\u0A36\u0A38\u0A39\u0A3C\u0A3E-\u0A42\u0A47\u0A48\u0A4B-\u0A4D\u0A51\u0A59-\u0A5C\u0A5E\u0A66-\u0A75\u0A81-\u0A83\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2\u0AB3\u0AB5-\u0AB9\u0ABC-\u0AC5\u0AC7-\u0AC9\u0ACB-\u0ACD\u0AD0\u0AE0-\u0AE3\u0AE6-\u0AEF\u0B01-\u0B03\u0B05-\u0B0C\u0B0F\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32\u0B33\u0B35-\u0B39\u0B3C-\u0B44\u0B47\u0B48\u0B4B-\u0B4D\u0B56\u0B57\u0B5C\u0B5D\u0B5F-\u0B63\u0B66-\u0B6F\u0B71\u0B82\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99\u0B9A\u0B9C\u0B9E\u0B9F\u0BA3\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BBE-\u0BC2\u0BC6-\u0BC8\u0BCA-\u0BCD\u0BD0\u0BD7\u0BE6-\u0BEF\u0C00-\u0C03\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D-\u0C44\u0C46-\u0C48\u0C4A-\u0C4D\u0C55\u0C56\u0C58\u0C59\u0C60-\u0C63\u0C66-\u0C6F\u0C81-\u0C83\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBC-\u0CC4\u0CC6-\u0CC8\u0CCA-\u0CCD\u0CD5\u0CD6\u0CDE\u0CE0-\u0CE3\u0CE6-\u0CEF\u0CF1\u0CF2\u0D01-\u0D03\u0D05-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D-\u0D44\u0D46-\u0D48\u0D4A-\u0D4E\u0D57\u0D60-\u0D63\u0D66-\u0D6F\u0D7A-\u0D7F\u0D82\u0D83\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0DCA\u0DCF-\u0DD4\u0DD6\u0DD8-\u0DDF\u0DE6-\u0DEF\u0DF2\u0DF3\u0E01-\u0E3A\u0E40-\u0E4E\u0E50-\u0E59\u0E81\u0E82\u0E84\u0E87\u0E88\u0E8A\u0E8D\u0E94-\u0E97\u0E99-\u0E9F\u0EA1-\u0EA3\u0EA5\u0EA7\u0EAA\u0EAB\u0EAD-\u0EB9\u0EBB-\u0EBD\u0EC0-\u0EC4\u0EC6\u0EC8-\u0ECD\u0ED0-\u0ED9\u0EDC-\u0EDF\u0F00\u0F18\u0F19\u0F20-\u0F29\u0F35\u0F37\u0F39\u0F3E-\u0F47\u0F49-\u0F6C\u0F71-\u0F84\u0F86-\u0F97\u0F99-\u0FBC\u0FC6\u1000-\u1049\u1050-\u109D\u10A0-\u10C5\u10C7\u10CD\u10D0-\u10FA\u10FC-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u135D-\u135F\u1369-\u1371\u1380-\u138F\u13A0-\u13F4\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16EE-\u16F8\u1700-\u170C\u170E-\u1714\u1720-\u1734\u1740-\u1753\u1760-\u176C\u176E-\u1770\u1772\u1773\u1780-\u17D3\u17D7\u17DC\u17DD\u17E0-\u17E9\u180B-\u180D\u1810-\u1819\u1820-\u1877\u1880-\u18AA\u18B0-\u18F5\u1900-\u191E\u1920-\u192B\u1930-\u193B\u1946-\u196D\u1970-\u1974\u1980-\u19AB\u19B0-\u19C9\u19D0-\u19DA\u1A00-\u1A1B\u1A20-\u1A5E\u1A60-\u1A7C\u1A7F-\u1A89\u1A90-\u1A99\u1AA7\u1AB0-\u1ABD\u1B00-\u1B4B\u1B50-\u1B59\u1B6B-\u1B73\u1B80-\u1BF3\u1C00-\u1C37\u1C40-\u1C49\u1C4D-\u1C7D\u1CD0-\u1CD2\u1CD4-\u1CF6\u1CF8\u1CF9\u1D00-\u1DF5\u1DFC-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FBC\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FCC\u1FD0-\u1FD3\u1FD6-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FF4\u1FF6-\u1FFC\u200C\u200D\u203F\u2040\u2054\u2071\u207F\u2090-\u209C\u20D0-\u20DC\u20E1\u20E5-\u20F0\u2102\u2107\u210A-\u2113\u2115\u2118-\u211D\u2124\u2126\u2128\u212A-\u2139\u213C-\u213F\u2145-\u2149\u214E\u2160-\u2188\u2C00-\u2C2E\u2C30-\u2C5E\u2C60-\u2CE4\u2CEB-\u2CF3\u2D00-\u2D25\u2D27\u2D2D\u2D30-\u2D67\u2D6F\u2D7F-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u2DE0-\u2DFF\u3005-\u3007\u3021-\u302F\u3031-\u3035\u3038-\u303C\u3041-\u3096\u3099-\u309F\u30A1-\u30FA\u30FC-\u30FF\u3105-\u312D\u3131-\u318E\u31A0-\u31BA\u31F0-\u31FF\u3400-\u4DB5\u4E00-\u9FCC\uA000-\uA48C\uA4D0-\uA4FD\uA500-\uA60C\uA610-\uA62B\uA640-\uA66F\uA674-\uA67D\uA67F-\uA69D\uA69F-\uA6F1\uA717-\uA71F\uA722-\uA788\uA78B-\uA78E\uA790-\uA7AD\uA7B0\uA7B1\uA7F7-\uA827\uA840-\uA873\uA880-\uA8C4\uA8D0-\uA8D9\uA8E0-\uA8F7\uA8FB\uA900-\uA92D\uA930-\uA953\uA960-\uA97C\uA980-\uA9C0\uA9CF-\uA9D9\uA9E0-\uA9FE\uAA00-\uAA36\uAA40-\uAA4D\uAA50-\uAA59\uAA60-\uAA76\uAA7A-\uAAC2\uAADB-\uAADD\uAAE0-\uAAEF\uAAF2-\uAAF6\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uAB30-\uAB5A\uAB5C-\uAB5F\uAB64\uAB65\uABC0-\uABEA\uABEC\uABED\uABF0-\uABF9\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB00-\uFB06\uFB13-\uFB17\uFB1D-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40\uFB41\uFB43\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE00-\uFE0F\uFE20-\uFE2D\uFE33\uFE34\uFE4D-\uFE4F\uFE70-\uFE74\uFE76-\uFEFC\uFF10-\uFF19\uFF21-\uFF3A\uFF3F\uFF41-\uFF5A\uFF66-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC]|\uD800[\uDC00-\uDC0B\uDC0D-\uDC26\uDC28-\uDC3A\uDC3C\uDC3D\uDC3F-\uDC4D\uDC50-\uDC5D\uDC80-\uDCFA\uDD40-\uDD74\uDDFD\uDE80-\uDE9C\uDEA0-\uDED0\uDEE0\uDF00-\uDF1F\uDF30-\uDF4A\uDF50-\uDF7A\uDF80-\uDF9D\uDFA0-\uDFC3\uDFC8-\uDFCF\uDFD1-\uDFD5]|\uD801[\uDC00-\uDC9D\uDCA0-\uDCA9\uDD00-\uDD27\uDD30-\uDD63\uDE00-\uDF36\uDF40-\uDF55\uDF60-\uDF67]|\uD802[\uDC00-\uDC05\uDC08\uDC0A-\uDC35\uDC37\uDC38\uDC3C\uDC3F-\uDC55\uDC60-\uDC76\uDC80-\uDC9E\uDD00-\uDD15\uDD20-\uDD39\uDD80-\uDDB7\uDDBE\uDDBF\uDE00-\uDE03\uDE05\uDE06\uDE0C-\uDE13\uDE15-\uDE17\uDE19-\uDE33\uDE38-\uDE3A\uDE3F\uDE60-\uDE7C\uDE80-\uDE9C\uDEC0-\uDEC7\uDEC9-\uDEE6\uDF00-\uDF35\uDF40-\uDF55\uDF60-\uDF72\uDF80-\uDF91]|\uD803[\uDC00-\uDC48]|\uD804[\uDC00-\uDC46\uDC66-\uDC6F\uDC7F-\uDCBA\uDCD0-\uDCE8\uDCF0-\uDCF9\uDD00-\uDD34\uDD36-\uDD3F\uDD50-\uDD73\uDD76\uDD80-\uDDC4\uDDD0-\uDDDA\uDE00-\uDE11\uDE13-\uDE37\uDEB0-\uDEEA\uDEF0-\uDEF9\uDF01-\uDF03\uDF05-\uDF0C\uDF0F\uDF10\uDF13-\uDF28\uDF2A-\uDF30\uDF32\uDF33\uDF35-\uDF39\uDF3C-\uDF44\uDF47\uDF48\uDF4B-\uDF4D\uDF57\uDF5D-\uDF63\uDF66-\uDF6C\uDF70-\uDF74]|\uD805[\uDC80-\uDCC5\uDCC7\uDCD0-\uDCD9\uDD80-\uDDB5\uDDB8-\uDDC0\uDE00-\uDE40\uDE44\uDE50-\uDE59\uDE80-\uDEB7\uDEC0-\uDEC9]|\uD806[\uDCA0-\uDCE9\uDCFF\uDEC0-\uDEF8]|\uD808[\uDC00-\uDF98]|\uD809[\uDC00-\uDC6E]|[\uD80C\uD840-\uD868\uD86A-\uD86C][\uDC00-\uDFFF]|\uD80D[\uDC00-\uDC2E]|\uD81A[\uDC00-\uDE38\uDE40-\uDE5E\uDE60-\uDE69\uDED0-\uDEED\uDEF0-\uDEF4\uDF00-\uDF36\uDF40-\uDF43\uDF50-\uDF59\uDF63-\uDF77\uDF7D-\uDF8F]|\uD81B[\uDF00-\uDF44\uDF50-\uDF7E\uDF8F-\uDF9F]|\uD82C[\uDC00\uDC01]|\uD82F[\uDC00-\uDC6A\uDC70-\uDC7C\uDC80-\uDC88\uDC90-\uDC99\uDC9D\uDC9E]|\uD834[\uDD65-\uDD69\uDD6D-\uDD72\uDD7B-\uDD82\uDD85-\uDD8B\uDDAA-\uDDAD\uDE42-\uDE44]|\uD835[\uDC00-\uDC54\uDC56-\uDC9C\uDC9E\uDC9F\uDCA2\uDCA5\uDCA6\uDCA9-\uDCAC\uDCAE-\uDCB9\uDCBB\uDCBD-\uDCC3\uDCC5-\uDD05\uDD07-\uDD0A\uDD0D-\uDD14\uDD16-\uDD1C\uDD1E-\uDD39\uDD3B-\uDD3E\uDD40-\uDD44\uDD46\uDD4A-\uDD50\uDD52-\uDEA5\uDEA8-\uDEC0\uDEC2-\uDEDA\uDEDC-\uDEFA\uDEFC-\uDF14\uDF16-\uDF34\uDF36-\uDF4E\uDF50-\uDF6E\uDF70-\uDF88\uDF8A-\uDFA8\uDFAA-\uDFC2\uDFC4-\uDFCB\uDFCE-\uDFFF]|\uD83A[\uDC00-\uDCC4\uDCD0-\uDCD6]|\uD83B[\uDE00-\uDE03\uDE05-\uDE1F\uDE21\uDE22\uDE24\uDE27\uDE29-\uDE32\uDE34-\uDE37\uDE39\uDE3B\uDE42\uDE47\uDE49\uDE4B\uDE4D-\uDE4F\uDE51\uDE52\uDE54\uDE57\uDE59\uDE5B\uDE5D\uDE5F\uDE61\uDE62\uDE64\uDE67-\uDE6A\uDE6C-\uDE72\uDE74-\uDE77\uDE79-\uDE7C\uDE7E\uDE80-\uDE89\uDE8B-\uDE9B\uDEA1-\uDEA3\uDEA5-\uDEA9\uDEAB-\uDEBB]|\uD869[\uDC00-\uDED6\uDF00-\uDFFF]|\uD86D[\uDC00-\uDF34\uDF40-\uDFFF]|\uD86E[\uDC00-\uDC1D]|\uD87E[\uDC00-\uDE1D]|\uDB40[\uDD00-\uDDEF]/
	    };

	    function isDecimalDigit(ch) {
	        return 0x30 <= ch && ch <= 0x39;  // 0..9
	    }

	    function isHexDigit(ch) {
	        return 0x30 <= ch && ch <= 0x39 ||  // 0..9
	            0x61 <= ch && ch <= 0x66 ||     // a..f
	            0x41 <= ch && ch <= 0x46;       // A..F
	    }

	    function isOctalDigit(ch) {
	        return ch >= 0x30 && ch <= 0x37;  // 0..7
	    }

	    // 7.2 White Space

	    NON_ASCII_WHITESPACES = [
	        0x1680, 0x180E,
	        0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005, 0x2006, 0x2007, 0x2008, 0x2009, 0x200A,
	        0x202F, 0x205F,
	        0x3000,
	        0xFEFF
	    ];

	    function isWhiteSpace(ch) {
	        return ch === 0x20 || ch === 0x09 || ch === 0x0B || ch === 0x0C || ch === 0xA0 ||
	            ch >= 0x1680 && NON_ASCII_WHITESPACES.indexOf(ch) >= 0;
	    }

	    // 7.3 Line Terminators

	    function isLineTerminator(ch) {
	        return ch === 0x0A || ch === 0x0D || ch === 0x2028 || ch === 0x2029;
	    }

	    // 7.6 Identifier Names and Identifiers

	    function fromCodePoint(cp) {
	        if (cp <= 0xFFFF) { return String.fromCharCode(cp); }
	        var cu1 = String.fromCharCode(Math.floor((cp - 0x10000) / 0x400) + 0xD800);
	        var cu2 = String.fromCharCode(((cp - 0x10000) % 0x400) + 0xDC00);
	        return cu1 + cu2;
	    }

	    IDENTIFIER_START = new Array(0x80);
	    for(ch = 0; ch < 0x80; ++ch) {
	        IDENTIFIER_START[ch] =
	            ch >= 0x61 && ch <= 0x7A ||  // a..z
	            ch >= 0x41 && ch <= 0x5A ||  // A..Z
	            ch === 0x24 || ch === 0x5F;  // $ (dollar) and _ (underscore)
	    }

	    IDENTIFIER_PART = new Array(0x80);
	    for(ch = 0; ch < 0x80; ++ch) {
	        IDENTIFIER_PART[ch] =
	            ch >= 0x61 && ch <= 0x7A ||  // a..z
	            ch >= 0x41 && ch <= 0x5A ||  // A..Z
	            ch >= 0x30 && ch <= 0x39 ||  // 0..9
	            ch === 0x24 || ch === 0x5F;  // $ (dollar) and _ (underscore)
	    }

	    function isIdentifierStartES5(ch) {
	        return ch < 0x80 ? IDENTIFIER_START[ch] : ES5Regex.NonAsciiIdentifierStart.test(fromCodePoint(ch));
	    }

	    function isIdentifierPartES5(ch) {
	        return ch < 0x80 ? IDENTIFIER_PART[ch] : ES5Regex.NonAsciiIdentifierPart.test(fromCodePoint(ch));
	    }

	    function isIdentifierStartES6(ch) {
	        return ch < 0x80 ? IDENTIFIER_START[ch] : ES6Regex.NonAsciiIdentifierStart.test(fromCodePoint(ch));
	    }

	    function isIdentifierPartES6(ch) {
	        return ch < 0x80 ? IDENTIFIER_PART[ch] : ES6Regex.NonAsciiIdentifierPart.test(fromCodePoint(ch));
	    }

	    module.exports = {
	        isDecimalDigit: isDecimalDigit,
	        isHexDigit: isHexDigit,
	        isOctalDigit: isOctalDigit,
	        isWhiteSpace: isWhiteSpace,
	        isLineTerminator: isLineTerminator,
	        isIdentifierStartES5: isIdentifierStartES5,
	        isIdentifierPartES5: isIdentifierPartES5,
	        isIdentifierStartES6: isIdentifierStartES6,
	        isIdentifierPartES6: isIdentifierPartES6
	    };
	}());
	/* vim: set sw=4 ts=4 et tw=80 : */
	});
	var code_1 = code.isDecimalDigit;
	var code_2 = code.isHexDigit;
	var code_3 = code.isOctalDigit;
	var code_4 = code.isWhiteSpace;
	var code_5 = code.isLineTerminator;
	var code_6 = code.isIdentifierStartES5;
	var code_7 = code.isIdentifierPartES5;
	var code_8 = code.isIdentifierStartES6;
	var code_9 = code.isIdentifierPartES6;

	var keyword = createCommonjsModule(function (module) {
	/*
	  Copyright (C) 2013 Yusuke Suzuki <utatane.tea@gmail.com>

	  Redistribution and use in source and binary forms, with or without
	  modification, are permitted provided that the following conditions are met:

	    * Redistributions of source code must retain the above copyright
	      notice, this list of conditions and the following disclaimer.
	    * Redistributions in binary form must reproduce the above copyright
	      notice, this list of conditions and the following disclaimer in the
	      documentation and/or other materials provided with the distribution.

	  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	  ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
	  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
	  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
	  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
	*/

	(function () {

	    var code$$1 = code;

	    function isStrictModeReservedWordES6(id) {
	        switch (id) {
	        case 'implements':
	        case 'interface':
	        case 'package':
	        case 'private':
	        case 'protected':
	        case 'public':
	        case 'static':
	        case 'let':
	            return true;
	        default:
	            return false;
	        }
	    }

	    function isKeywordES5(id, strict) {
	        // yield should not be treated as keyword under non-strict mode.
	        if (!strict && id === 'yield') {
	            return false;
	        }
	        return isKeywordES6(id, strict);
	    }

	    function isKeywordES6(id, strict) {
	        if (strict && isStrictModeReservedWordES6(id)) {
	            return true;
	        }

	        switch (id.length) {
	        case 2:
	            return (id === 'if') || (id === 'in') || (id === 'do');
	        case 3:
	            return (id === 'var') || (id === 'for') || (id === 'new') || (id === 'try');
	        case 4:
	            return (id === 'this') || (id === 'else') || (id === 'case') ||
	                (id === 'void') || (id === 'with') || (id === 'enum');
	        case 5:
	            return (id === 'while') || (id === 'break') || (id === 'catch') ||
	                (id === 'throw') || (id === 'const') || (id === 'yield') ||
	                (id === 'class') || (id === 'super');
	        case 6:
	            return (id === 'return') || (id === 'typeof') || (id === 'delete') ||
	                (id === 'switch') || (id === 'export') || (id === 'import');
	        case 7:
	            return (id === 'default') || (id === 'finally') || (id === 'extends');
	        case 8:
	            return (id === 'function') || (id === 'continue') || (id === 'debugger');
	        case 10:
	            return (id === 'instanceof');
	        default:
	            return false;
	        }
	    }

	    function isReservedWordES5(id, strict) {
	        return id === 'null' || id === 'true' || id === 'false' || isKeywordES5(id, strict);
	    }

	    function isReservedWordES6(id, strict) {
	        return id === 'null' || id === 'true' || id === 'false' || isKeywordES6(id, strict);
	    }

	    function isRestrictedWord(id) {
	        return id === 'eval' || id === 'arguments';
	    }

	    function isIdentifierNameES5(id) {
	        var i, iz, ch;

	        if (id.length === 0) { return false; }

	        ch = id.charCodeAt(0);
	        if (!code$$1.isIdentifierStartES5(ch)) {
	            return false;
	        }

	        for (i = 1, iz = id.length; i < iz; ++i) {
	            ch = id.charCodeAt(i);
	            if (!code$$1.isIdentifierPartES5(ch)) {
	                return false;
	            }
	        }
	        return true;
	    }

	    function decodeUtf16(lead, trail) {
	        return (lead - 0xD800) * 0x400 + (trail - 0xDC00) + 0x10000;
	    }

	    function isIdentifierNameES6(id) {
	        var i, iz, ch, lowCh, check;

	        if (id.length === 0) { return false; }

	        check = code$$1.isIdentifierStartES6;
	        for (i = 0, iz = id.length; i < iz; ++i) {
	            ch = id.charCodeAt(i);
	            if (0xD800 <= ch && ch <= 0xDBFF) {
	                ++i;
	                if (i >= iz) { return false; }
	                lowCh = id.charCodeAt(i);
	                if (!(0xDC00 <= lowCh && lowCh <= 0xDFFF)) {
	                    return false;
	                }
	                ch = decodeUtf16(ch, lowCh);
	            }
	            if (!check(ch)) {
	                return false;
	            }
	            check = code$$1.isIdentifierPartES6;
	        }
	        return true;
	    }

	    function isIdentifierES5(id, strict) {
	        return isIdentifierNameES5(id) && !isReservedWordES5(id, strict);
	    }

	    function isIdentifierES6(id, strict) {
	        return isIdentifierNameES6(id) && !isReservedWordES6(id, strict);
	    }

	    module.exports = {
	        isKeywordES5: isKeywordES5,
	        isKeywordES6: isKeywordES6,
	        isReservedWordES5: isReservedWordES5,
	        isReservedWordES6: isReservedWordES6,
	        isRestrictedWord: isRestrictedWord,
	        isIdentifierNameES5: isIdentifierNameES5,
	        isIdentifierNameES6: isIdentifierNameES6,
	        isIdentifierES5: isIdentifierES5,
	        isIdentifierES6: isIdentifierES6
	    };
	}());
	/* vim: set sw=4 ts=4 et tw=80 : */
	});
	var keyword_1 = keyword.isKeywordES5;
	var keyword_2 = keyword.isKeywordES6;
	var keyword_3 = keyword.isReservedWordES5;
	var keyword_4 = keyword.isReservedWordES6;
	var keyword_5 = keyword.isRestrictedWord;
	var keyword_6 = keyword.isIdentifierNameES5;
	var keyword_7 = keyword.isIdentifierNameES6;
	var keyword_8 = keyword.isIdentifierES5;
	var keyword_9 = keyword.isIdentifierES6;

	var utils = createCommonjsModule(function (module, exports) {
	/*
	  Copyright (C) 2013 Yusuke Suzuki <utatane.tea@gmail.com>

	  Redistribution and use in source and binary forms, with or without
	  modification, are permitted provided that the following conditions are met:

	    * Redistributions of source code must retain the above copyright
	      notice, this list of conditions and the following disclaimer.
	    * Redistributions in binary form must reproduce the above copyright
	      notice, this list of conditions and the following disclaimer in the
	      documentation and/or other materials provided with the distribution.

	  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	  ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
	  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
	  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
	  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
	*/


	(function () {

	    exports.ast = ast;
	    exports.code = code;
	    exports.keyword = keyword;
	}());
	/* vim: set sw=4 ts=4 et tw=80 : */
	});
	var utils_1 = utils.ast;
	var utils_2 = utils.code;
	var utils_3 = utils.keyword;

	var makeMap = function makeMap (str) {
	  var map = Object.create(null);
	  var list = str.split(',');
	  for (var i = 0; i < list.length; i++) {
	    map[list[i]] = true;
	  }
	  return val => map[val]
	};

	var isTopLevel = makeMap('class,staticClass,style,key,ref,refInFor,slot,scopedSlots');
	var isNestable = makeMap('domProps,on,nativeOn,hook');
	var nestableRE = /^(domProps|on|nativeOn|hook)([\-_A-Z])/;
	var dirRE = /^v-/;
	var xlinkRE = /^xlink([A-Z])/;

	var groupProps = function groupProps (props, t) {
	  var newProps = [];
	  var currentNestedObjects = Object.create(null);
	  props.forEach(function (prop) {
	    var name = prop.key.value || prop.key.name;
	    if (isTopLevel(name)) {
	      // top-level special props
	      newProps.push(prop);
	    } else {
	      // nested modules
	      var nestMatch = name.match(nestableRE);
	      if (nestMatch) {
	        var prefix = nestMatch[1];
	        var suffix = name.replace(nestableRE, function (_, $1, $2) {
	          return $2 === '-' ? '' : $2.toLowerCase()
	        });
	        var nestedProp = t.objectProperty(t.stringLiteral(suffix), prop.value);
	        var nestedObject = currentNestedObjects[prefix];
	        if (!nestedObject) {
	          nestedObject = currentNestedObjects[prefix] = t.objectProperty(
	            t.identifier(prefix),
	            t.objectExpression([nestedProp])
	          );
	          newProps.push(nestedObject);
	        } else {
	          nestedObject.value.properties.push(nestedProp);
	        }
	      } else if (dirRE.test(name)) {
	        // custom directive
	        name = name.replace(dirRE, '');
	        var dirs = currentNestedObjects.directives;
	        if (!dirs) {
	          dirs = currentNestedObjects.directives = t.objectProperty(
	            t.identifier('directives'),
	            t.arrayExpression([])
	          );
	          newProps.push(dirs);
	        }
	        dirs.value.elements.push(t.objectExpression([
	          t.objectProperty(
	            t.identifier('name'),
	            t.stringLiteral(name)
	          ),
	          t.objectProperty(
	            t.identifier('value'),
	            prop.value
	          )
	        ]));
	      } else {
	        // rest are nested under attrs
	        var attrs = currentNestedObjects.attrs;
	        // guard xlink attributes
	        if (xlinkRE.test(prop.key.name)) {
	          prop.key.name = JSON.stringify(prop.key.name.replace(xlinkRE, function (m, p1) {
	            return 'xlink:' + p1.toLowerCase()
	          }));
	        }
	        if (!attrs) {
	          attrs = currentNestedObjects.attrs = t.objectProperty(
	            t.identifier('attrs'),
	            t.objectExpression([prop])
	          );
	          newProps.push(attrs);
	        } else {
	          attrs.value.properties.push(prop);
	        }
	      }
	    }
	  });
	  return t.objectExpression(newProps)
	};

	const acceptValue = ['input','textarea','option','select'];
	var mustUseProp = (tag, type, attr) => {
	  return (
	    (attr === 'value' && acceptValue.includes(tag)) && type !== 'button' ||
	    (attr === 'selected' && tag === 'option') ||
	    (attr === 'checked' && tag === 'input') ||
	    (attr === 'muted' && tag === 'video')
	  )
	};

	var lib = createCommonjsModule(function (module, exports) {

	exports.__esModule = true;

	exports.default = function () {
	  return {
	    manipulateOptions: function manipulateOptions(opts, parserOpts) {
	      parserOpts.plugins.push("jsx");
	    }
	  };
	};

	module.exports = exports["default"];
	});

	unwrapExports(lib);

	var babelPluginTransformVueJsx = function (babel) {
	  var t = babel.types;

	  return {
	    inherits: lib,
	    visitor: {
	      JSXNamespacedName (path) {
	        throw path.buildCodeFrameError(
	          'Namespaced tags/attributes are not supported. JSX is not XML.\n' +
	          'For attributes like xlink:href, use xlinkHref instead.'
	        )
	      },
	      JSXElement: {
	        exit (path, file) {
	          // turn tag into createElement call
	          var callExpr = buildElementCall(path.get('openingElement'), file);
	          // add children array as 3rd arg
	          callExpr.arguments.push(t.arrayExpression(path.node.children));
	          if (callExpr.arguments.length >= 3) {
	            callExpr._prettyCall = true;
	          }
	          path.replaceWith(t.inherits(callExpr, path.node));
	        }
	      },
	      'Program' (path) {
	        path.traverse({
	          'ObjectMethod|ClassMethod' (path) {
	            const params = path.get('params');
	            // do nothing if there is (h) param
	            if (params.length && params[0].node.name === 'h') {
	              return
	            }
	            // do nothing if there is no JSX inside
	            const jsxChecker = {
	              hasJsx: false
	            };
	            path.traverse({
	              JSXElement () {
	                this.hasJsx = true;
	              }
	            }, jsxChecker);
	            if (!jsxChecker.hasJsx) {
	              return
	            }
	            const isRender = path.node.key.name === 'render';
	            // inject h otherwise
	            path.get('body').unshiftContainer('body', t.variableDeclaration('const', [
	              t.variableDeclarator(
	                t.identifier('h'),
	                (
	                  isRender
	                    ? t.memberExpression(
	                      t.identifier('arguments'),
	                      t.numericLiteral(0),
	                      true
	                    )
	                    : t.memberExpression(
	                      t.thisExpression(),
	                      t.identifier('$createElement')
	                    )
	                )
	              )
	            ]));
	          },
	          JSXOpeningElement (path) {
	            const tag = path.get('name').node.name;
	            const attributes = path.get('attributes');
	            const typeAttribute = attributes.find(attributePath => attributePath.node.name && attributePath.node.name.name === 'type');
	            const type = typeAttribute && t.isStringLiteral(typeAttribute.node.value) ? typeAttribute.node.value.value : null;

	            attributes.forEach(attributePath => {
	              const attribute = attributePath.get('name');

	              if (!attribute.node) {
	                return
	              }

	              const attr = attribute.node.name;

	              if (mustUseProp(tag, type, attr) && t.isJSXExpressionContainer(attributePath.node.value)) {
	                attribute.replaceWith(t.JSXIdentifier(`domProps-${attr}`));
	              }
	            });
	          }
	        });
	      }
	    }
	  }

	  function buildElementCall (path, file) {
	    path.parent.children = t.react.buildChildren(path.parent);
	    var tagExpr = convertJSXIdentifier(path.node.name, path.node);
	    var args = [];

	    var tagName;
	    if (t.isIdentifier(tagExpr)) {
	      tagName = tagExpr.name;
	    } else if (t.isLiteral(tagExpr)) {
	      tagName = tagExpr.value;
	    }

	    if (t.react.isCompatTag(tagName)) {
	      args.push(t.stringLiteral(tagName));
	    } else {
	      args.push(tagExpr);
	    }

	    var attribs = path.node.attributes;
	    if (attribs.length) {
	      attribs = buildOpeningElementAttributes(attribs, file);
	    } else {
	      attribs = t.nullLiteral();
	    }
	    args.push(attribs);

	    return t.callExpression(t.identifier('h'), args)
	  }

	  function convertJSXIdentifier (node, parent) {
	    if (t.isJSXIdentifier(node)) {
	      if (node.name === 'this' && t.isReferenced(node, parent)) {
	        return t.thisExpression()
	      } else if (utils.keyword.isIdentifierNameES6(node.name)) {
	        node.type = 'Identifier';
	      } else {
	        return t.stringLiteral(node.name)
	      }
	    } else if (t.isJSXMemberExpression(node)) {
	      return t.memberExpression(
	        convertJSXIdentifier(node.object, node),
	        convertJSXIdentifier(node.property, node)
	      )
	    }
	    return node
	  }

	  /**
	   * The logic for this is quite terse. It's because we need to
	   * support spread elements. We loop over all attributes,
	   * breaking on spreads, we then push a new object containing
	   * all prior attributes to an array for later processing.
	   */

	  function buildOpeningElementAttributes (attribs, file) {
	    var _props = [];
	    var objs = [];

	    function pushProps () {
	      if (!_props.length) return
	      objs.push(t.objectExpression(_props));
	      _props = [];
	    }

	    while (attribs.length) {
	      var prop = attribs.shift();
	      if (t.isJSXSpreadAttribute(prop)) {
	        pushProps();
	        prop.argument._isSpread = true;
	        objs.push(prop.argument);
	      } else {
	        _props.push(convertAttribute(prop));
	      }
	    }

	    pushProps();

	    objs = objs.map(function (o) {
	      return o._isSpread ? o : groupProps(o.properties, t)
	    });

	    if (objs.length === 1) {
	      // only one object
	      attribs = objs[0];
	    } else if (objs.length) {
	      // add prop merging helper
	      var helper = file.addImport('babel-helper-vue-jsx-merge-props', 'default', '_mergeJSXProps');
	      // spread it
	      attribs = t.callExpression(
	        helper,
	        [t.arrayExpression(objs)]
	      );
	    }
	    return attribs
	  }

	  function convertAttribute (node) {
	    var value = convertAttributeValue(node.value || t.booleanLiteral(true));
	    if (t.isStringLiteral(value) && !t.isJSXExpressionContainer(node.value)) {
	      value.value = value.value.replace(/\n\s+/g, ' ');
	    }
	    if (t.isValidIdentifier(node.name.name)) {
	      node.name.type = 'Identifier';
	    } else {
	      node.name = t.stringLiteral(node.name.name);
	    }
	    return t.inherits(t.objectProperty(node.name, value), node)
	  }

	  function convertAttributeValue (node) {
	    if (t.isJSXExpressionContainer(node)) {
	      return node.expression
	    } else {
	      return node
	    }
	  }
	};

	function _interopDefault$1 (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

	var syntaxJsx = _interopDefault$1(lib);

	var groupEventAttributes = (function (t) {
	  return function (obj, attribute) {
	    if (t.isJSXSpreadAttribute(attribute)) {
	      return obj;
	    }

	    var isNamespaced = t.isJSXNamespacedName(attribute.get('name'));
	    var event = (isNamespaced ? attribute.get('name').get('namespace') : attribute.get('name')).get('name').node;
	    var modifiers = isNamespaced ? new Set(attribute.get('name').get('name').get('name').node.split('-')) : new Set();

	    if (event.indexOf('on') !== 0) {
	      return obj;
	    }

	    var value = attribute.get('value');

	    attribute.remove();
	    if (!t.isJSXExpressionContainer(value)) {
	      return obj;
	    }

	    var expression = value.get('expression').node;

	    var eventName = event.substr(2);
	    if (eventName[0] === '-') {
	      eventName = eventName.substr(1);
	    }
	    eventName = eventName[0].toLowerCase() + eventName.substr(1);
	    if (modifiers.has('capture')) {
	      eventName = '!' + eventName;
	    }
	    if (modifiers.has('once')) {
	      eventName = '~' + eventName;
	    }

	    if (!obj[eventName]) {
	      obj[eventName] = [];
	    }

	    obj[eventName].push({ modifiers, expression, attribute });

	    return obj;
	  };
	});

	var aliases = {
	  esc: 27,
	  tab: 9,
	  enter: 13,
	  space: 32,
	  up: 38,
	  left: 37,
	  right: 39,
	  down: 40,
	  delete: [8, 46]
	};

	var keyModifiers = ['ctrl', 'shift', 'alt', 'meta'];

	var keyCodeRE = /^k(\d{1,})$/;

	var generateBindingBody = (function (t, _ref) {
	  var modifiers = _ref.modifiers,
	      expression = _ref.expression;

	  var callStatement = t.expressionStatement(t.callExpression(expression, [t.identifier('$event')]));
	  var result = [];
	  var conditions = [];
	  var keyConditions = [t.unaryExpression('!', t.binaryExpression('in', t.stringLiteral('button'), t.identifier('$event')))];

	  modifiers.forEach(function (modifier) {
	    if (modifier === 'stop') {
	      result.push(t.expressionStatement(t.callExpression(t.memberExpression(t.identifier('$event'), t.identifier('stopPropagation')), [])));
	    } else if (modifier === 'prevent') {
	      result.push(t.expressionStatement(t.callExpression(t.memberExpression(t.identifier('$event'), t.identifier('preventDefault')), [])));
	    } else if (modifier === 'self') {
	      conditions.push(t.binaryExpression('!==', t.memberExpression(t.identifier('$event'), t.identifier('target')), t.memberExpression(t.identifier('$event'), t.identifier('currentTarget'))));
	    } else if (keyModifiers.includes(modifier)) {
	      conditions.push(t.unaryExpression('!', t.memberExpression(t.identifier('$event'), t.identifier(`${modifier}Key`))));
	    } else if (modifier === 'bare') {
	      conditions.push(keyModifiers.filter(function (keyModifier) {
	        return !modifiers.has(keyModifier);
	      }).map(function (keyModifier) {
	        return t.memberExpression(t.identifier('$event'), t.identifier(`${keyModifier}Key`));
	      }).reduce(function (leftCondition, rightCondition) {
	        return t.logicalExpression('||', leftCondition, rightCondition);
	      }));
	    } else if (aliases[modifier]) {
	      keyConditions.push(t.callExpression(t.memberExpression(t.thisExpression(), t.identifier('_k')), [t.memberExpression(t.identifier('$event'), t.identifier('keyCode')), t.stringLiteral(modifier), Array.isArray(aliases[modifier]) ? t.arrayExpression(aliases[modifier].map(function (el) {
	        return t.numericLiteral(el);
	      })) : t.numericLiteral(aliases[modifier])]));
	    } else if (modifier.match(keyCodeRE)) {
	      var keyCode = +modifier.match(keyCodeRE)[1];
	      keyConditions.push(t.binaryExpression('!==', t.memberExpression(t.identifier('$event'), t.identifier('keyCode')), t.numericLiteral(keyCode)));
	    }
	  });

	  if (keyConditions.length > 1) {
	    conditions.push(keyConditions.reduce(function (leftCondition, rightCondition) {
	      return t.logicalExpression('&&', leftCondition, rightCondition);
	    }));
	  }

	  if (conditions.length > 0) {
	    result.push(t.ifStatement(conditions.reduce(function (leftCondition, rightCondition) {
	      return t.logicalExpression('||', leftCondition, rightCondition);
	    }), t.returnStatement(t.nullLiteral())));
	  }

	  result.push(callStatement);
	  return result;
	});

	var generateBindingsList = (function (t, bindings) {
	  return bindings.map(function (binding) {
	    return t.arrowFunctionExpression([t.identifier('$event')], t.blockStatement(generateBindingBody(t, binding)));
	  });
	});

	var _slicedToArray = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

	var generateSpreadEvent = (function (t) {
	  return function (_ref) {
	    var _ref2 = _slicedToArray(_ref, 2),
	        event = _ref2[0],
	        bindings = _ref2[1];

	    var callbacks = generateBindingsList(t, bindings);
	    return t.objectProperty(t.stringLiteral(event), callbacks.length === 1 ? callbacks[0] : t.arrayExpression(callbacks));
	  };
	});

	var index$1 = (function (_ref) {
	  var t = _ref.types;
	  return {
	    inherits: syntaxJsx,
	    visitor: {
	      Program(path) {
	        path.traverse({
	          JSXOpeningElement(path) {
	            var attributes = path.get('attributes');
	            var events = Object.entries(attributes.reduce(groupEventAttributes(t), {}));
	            if (events.length > 0) {
	              path.pushContainer('attributes', t.jSXSpreadAttribute(t.objectExpression([t.objectProperty(t.identifier('on'), t.objectExpression(events.map(generateSpreadEvent(t))))])));
	            }
	          }
	        });
	      }
	    }
	  };
	});

	var bundle = index$1;

	var htmlTags = [
		"a",
		"abbr",
		"address",
		"area",
		"article",
		"aside",
		"audio",
		"b",
		"base",
		"bdi",
		"bdo",
		"blockquote",
		"body",
		"br",
		"button",
		"canvas",
		"caption",
		"cite",
		"code",
		"col",
		"colgroup",
		"data",
		"datalist",
		"dd",
		"del",
		"details",
		"dfn",
		"dialog",
		"div",
		"dl",
		"dt",
		"em",
		"embed",
		"fieldset",
		"figcaption",
		"figure",
		"footer",
		"form",
		"h1",
		"h2",
		"h3",
		"h4",
		"h5",
		"h6",
		"head",
		"header",
		"hgroup",
		"hr",
		"html",
		"i",
		"iframe",
		"img",
		"input",
		"ins",
		"kbd",
		"keygen",
		"label",
		"legend",
		"li",
		"link",
		"main",
		"map",
		"mark",
		"math",
		"menu",
		"menuitem",
		"meta",
		"meter",
		"nav",
		"noscript",
		"object",
		"ol",
		"optgroup",
		"option",
		"output",
		"p",
		"param",
		"picture",
		"pre",
		"progress",
		"q",
		"rb",
		"rp",
		"rt",
		"rtc",
		"ruby",
		"s",
		"samp",
		"script",
		"section",
		"select",
		"slot",
		"small",
		"source",
		"span",
		"strong",
		"style",
		"sub",
		"summary",
		"sup",
		"svg",
		"table",
		"tbody",
		"td",
		"template",
		"textarea",
		"tfoot",
		"th",
		"thead",
		"time",
		"title",
		"tr",
		"track",
		"u",
		"ul",
		"var",
		"video",
		"wbr"
	]
	;

	var htmlTags$1 = /*#__PURE__*/Object.freeze({
		default: htmlTags
	});

	var require$$0 = ( htmlTags$1 && htmlTags ) || htmlTags$1;

	var htmlTags$2 = require$$0;

	var svgTags = [
		"a",
		"altGlyph",
		"altGlyphDef",
		"altGlyphItem",
		"animate",
		"animateColor",
		"animateMotion",
		"animateTransform",
		"circle",
		"clipPath",
		"color-profile",
		"cursor",
		"defs",
		"desc",
		"ellipse",
		"feBlend",
		"feColorMatrix",
		"feComponentTransfer",
		"feComposite",
		"feConvolveMatrix",
		"feDiffuseLighting",
		"feDisplacementMap",
		"feDistantLight",
		"feFlood",
		"feFuncA",
		"feFuncB",
		"feFuncG",
		"feFuncR",
		"feGaussianBlur",
		"feImage",
		"feMerge",
		"feMergeNode",
		"feMorphology",
		"feOffset",
		"fePointLight",
		"feSpecularLighting",
		"feSpotLight",
		"feTile",
		"feTurbulence",
		"filter",
		"font",
		"font-face",
		"font-face-format",
		"font-face-name",
		"font-face-src",
		"font-face-uri",
		"foreignObject",
		"g",
		"glyph",
		"glyphRef",
		"hkern",
		"image",
		"line",
		"linearGradient",
		"marker",
		"mask",
		"metadata",
		"missing-glyph",
		"mpath",
		"path",
		"pattern",
		"polygon",
		"polyline",
		"radialGradient",
		"rect",
		"script",
		"set",
		"stop",
		"style",
		"svg",
		"switch",
		"symbol",
		"text",
		"textPath",
		"title",
		"tref",
		"tspan",
		"use",
		"view",
		"vkern"
	];

	var svgTags$1 = /*#__PURE__*/Object.freeze({
		default: svgTags
	});

	var require$$0$1 = ( svgTags$1 && svgTags ) || svgTags$1;

	var lib$1 = require$$0$1;

	var allowedModifiers = ['trim', 'number', 'lazy'];
	var RANGE_TOKEN = '__r';
	var CHECKBOX_RADIO_TOKEN = '__c';





	var isReservedTag = function isReservedTag(tag) {
	  return ~htmlTags$2.indexOf(tag) || ~lib$1.indexOf(tag)
	};

	var getExpression = function getExpression(t, path) {
	  return t.isStringLiteral(path.node.value) ? path.node.value : path.node.value.expression
	};

	var genValue = function genValue(t, model) {
	  return t.jSXAttribute(t.jSXIdentifier('domPropsValue'), t.jSXExpressionContainer(model))
	};

	var genAssignmentCode = function genAssignmentCode(t, model, assignment) {
	  if (model.computed) {
	    var object = model.object,
	      property = model.property;

	    return t.ExpressionStatement(
	      t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('$set')), [object, property, assignment])
	    )
	  } else {
	    return t.ExpressionStatement(t.AssignmentExpression('=', model, assignment))
	  }
	};

	var genListener = function genListener(t, event, body) {
	  return t.jSXAttribute(
	    t.jSXIdentifier('on' + event),
	    t.jSXExpressionContainer(t.ArrowFunctionExpression([t.Identifier('$event')], t.BlockStatement(body)))
	  )
	};

	var genSelectModel = function genSelectModel(t, modelAttribute, model, modifier) {
	  if (modifier && modifier !== 'number') {
	    throw modelAttribute.get('name').get('name').buildCodeFrameError('you can only use number modifier with <select/ >')
	  }

	  var number = modifier === 'number';

	  var valueGetter = t.ConditionalExpression(
	    t.BinaryExpression('in', t.StringLiteral('_value'), t.Identifier('o')),
	    t.MemberExpression(t.Identifier('o'), t.Identifier('_value')),
	    t.MemberExpression(t.Identifier('o'), t.Identifier('value'))
	  );

	  var selectedVal = t.CallExpression(
	    t.MemberExpression(
	      t.CallExpression(
	        t.MemberExpression(
	          t.MemberExpression(
	            t.MemberExpression(t.Identifier('Array'), t.Identifier('prototype')),
	            t.Identifier('filter')
	          ),
	          t.Identifier('call')
	        ),
	        [
	          t.MemberExpression(
	            t.MemberExpression(t.Identifier('$event'), t.Identifier('target')),
	            t.Identifier('options')
	          ),
	          t.ArrowFunctionExpression(
	            [t.Identifier('o')],
	            t.MemberExpression(t.Identifier('o'), t.Identifier('selected'))
	          )
	        ]
	      ),
	      t.Identifier('map')
	    ),
	    [
	      t.ArrowFunctionExpression(
	        [t.Identifier('o')],
	        number
	          ? t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_n')), [valueGetter])
	          : valueGetter
	      )
	    ]
	  );

	  var assignment = t.ConditionalExpression(
	    t.MemberExpression(t.MemberExpression(t.Identifier('$event'), t.Identifier('target')), t.Identifier('multiple')),
	    t.Identifier('$$selectedVal'),
	    t.MemberExpression(t.Identifier('$$selectedVal'), t.NumericLiteral(0), true)
	  );

	  var code = t.VariableDeclaration('const', [t.VariableDeclarator(t.Identifier('$$selectedVal'), selectedVal)]);

	  return [genValue(t, model), genListener(t, 'Change', [code, genAssignmentCode(t, model, assignment)])]
	};

	var genCheckboxModel = function genCheckboxModel(t, modelAttribute, model, modifier, path) {
	  if (modifier && modifier !== 'number') {
	    throw modelAttribute
	      .get('name')
	      .get('name')
	      .buildCodeFrameError('you can only use number modifier with input[type="checkbox"]')
	  }

	  var value = t.NullLiteral();
	  var trueValue = t.BooleanLiteral(true);
	  var falseValue = t.BooleanLiteral(false);

	  path.get('attributes').forEach(function(path) {
	    if (!path.node.name) {
	      return
	    }

	    if (path.node.name.name === 'value') {
	      value = getExpression(t, path);
	      path.remove();
	    } else if (path.node.name.name === 'true-value') {
	      trueValue = getExpression(t, path);
	      path.remove();
	    } else if (path.node.name.name === 'false-value') {
	      falseValue = getExpression(t, path);
	      path.remove();
	    }
	  });

	  var checkedProp = t.JSXAttribute(
	    t.JSXIdentifier('checked'),
	    t.JSXExpressionContainer(
	      t.ConditionalExpression(
	        t.CallExpression(t.MemberExpression(t.Identifier('Array'), t.Identifier('isArray')), [model]),
	        t.BinaryExpression(
	          '>',
	          t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_i')), [model, value]),
	          t.UnaryExpression('-', t.NumericLiteral(1))
	        ),
	        t.isBooleanLiteral(trueValue) && trueValue.value === true
	          ? model
	          : t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_q')), [model, trueValue])
	      )
	    )
	  );

	  var handlerProp = t.JSXAttribute(
	    t.JSXIdentifier('on' + CHECKBOX_RADIO_TOKEN),
	    t.JSXExpressionContainer(
	      t.ArrowFunctionExpression(
	        [t.Identifier('$event')],
	        t.BlockStatement([
	          t.VariableDeclaration('const', [
	            t.VariableDeclarator(t.Identifier('$$a'), model),
	            t.VariableDeclarator(
	              t.Identifier('$$el'),
	              t.MemberExpression(t.Identifier('$event'), t.Identifier('target'))
	            ),
	            t.VariableDeclarator(
	              t.Identifier('$$c'),
	              t.ConditionalExpression(
	                t.MemberExpression(t.Identifier('$$el'), t.Identifier('checked')),
	                trueValue,
	                falseValue
	              )
	            )
	          ]),
	          t.IfStatement(
	            t.CallExpression(t.MemberExpression(t.Identifier('Array'), t.Identifier('isArray')), [t.Identifier('$$a')]),
	            t.BlockStatement([
	              t.VariableDeclaration('const', [
	                t.VariableDeclarator(
	                  t.Identifier('$$v'),
	                  modifier === 'number'
	                    ? t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_n')), [value])
	                    : value
	                ),
	                t.VariableDeclarator(
	                  t.Identifier('$$i'),
	                  t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_i')), [
	                    t.Identifier('$$a'),
	                    t.Identifier('$$v')
	                  ])
	                )
	              ]),
	              t.IfStatement(
	                t.MemberExpression(t.Identifier('$$el'), t.Identifier('checked')),
	                t.BlockStatement([
	                  t.ExpressionStatement(
	                    t.LogicalExpression(
	                      '&&',
	                      t.BinaryExpression('<', t.Identifier('$$i'), t.NumericLiteral(0)),
	                      t.AssignmentExpression(
	                        '=',
	                        model,
	                        t.CallExpression(t.MemberExpression(t.Identifier('$$a'), t.Identifier('concat')), [
	                          t.Identifier('$$v')
	                        ])
	                      )
	                    )
	                  )
	                ]),
	                t.BlockStatement([
	                  t.ExpressionStatement(
	                    t.LogicalExpression(
	                      '&&',
	                      t.BinaryExpression('>', t.Identifier('$$i'), t.UnaryExpression('-', t.NumericLiteral(1))),
	                      t.AssignmentExpression(
	                        '=',
	                        model,
	                        t.CallExpression(
	                          t.MemberExpression(
	                            t.CallExpression(t.MemberExpression(t.Identifier('$$a'), t.Identifier('slice')), [
	                              t.NumericLiteral(0),
	                              t.Identifier('$$i')
	                            ]),
	                            t.Identifier('concat')
	                          ),
	                          [
	                            t.CallExpression(t.MemberExpression(t.Identifier('$$a'), t.Identifier('slice')), [
	                              t.BinaryExpression('+', t.Identifier('$$i'), t.NumericLiteral(1))
	                            ])
	                          ]
	                        )
	                      )
	                    )
	                  )
	                ])
	              )
	            ]),
	            t.BlockStatement([genAssignmentCode(t, model, t.Identifier('$$c'))])
	          )
	        ])
	      )
	    )
	  );

	  return [checkedProp, handlerProp]
	};

	var genRadioModel = function genRadioModel(t, modelAttribute, model, modifier, path) {
	  if (modifier && modifier !== 'number') {
	    throw modelAttribute
	      .get('name')
	      .get('name')
	      .buildCodeFrameError('you can only use number modifier with input[type="radio"]')
	  }

	  var value = t.BooleanLiteral(true);

	  path.get('attributes').forEach(function(path) {
	    if (!path.node.name) {
	      return
	    }

	    if (path.node.name.name === 'value') {
	      value = getExpression(t, path);
	      path.remove();
	    }
	  });

	  var checkedProp = t.JSXAttribute(
	    t.JSXIdentifier('checked'),
	    t.JSXExpressionContainer(
	      t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_q')), [model, value])
	    )
	  );

	  var handlerProp = t.JSXAttribute(
	    t.JSXIdentifier('on' + CHECKBOX_RADIO_TOKEN),
	    t.JSXExpressionContainer(
	      t.ArrowFunctionExpression(
	        [t.Identifier('$event')],
	        t.BlockStatement([
	          genAssignmentCode(
	            t,
	            model,
	            modifier === 'number'
	              ? t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_n')), [value])
	              : value
	          )
	        ])
	      )
	    )
	  );

	  return [checkedProp, handlerProp]
	};

	var genDefaultModel = function genDefaultModel(t, modelAttribute, model, modifier, path, type) {
	  var needCompositionGuard = modifier !== 'lazy' && type !== 'range';

	  var event = modifier === 'lazy' ? 'Change' : type === 'range' ? RANGE_TOKEN : 'Input';

	  var valueExpression = t.MemberExpression(
	    t.MemberExpression(t.Identifier('$event'), t.Identifier('target')),
	    t.Identifier('value')
	  );

	  if (modifier === 'trim') {
	    valueExpression = t.CallExpression(t.MemberExpression(valueExpression, t.Identifier('trim')), []);
	  } else if (modifier === 'number') {
	    valueExpression = t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_n')), [valueExpression]);
	  }

	  var code = genAssignmentCode(t, model, valueExpression);

	  if (needCompositionGuard) {
	    code = t.BlockStatement([
	      t.IfStatement(
	        t.MemberExpression(
	          t.MemberExpression(t.Identifier('$event'), t.Identifier('target')),
	          t.Identifier('composing')
	        ),
	        t.ReturnStatement(null)
	      ),
	      code
	    ]);
	  } else {
	    code = t.BlockStatement([code]);
	  }

	  var valueProp = t.JSXAttribute(t.jSXIdentifier('domPropsValue'), t.JSXExpressionContainer(model));

	  var handlerProp = t.JSXAttribute(
	    t.JSXIdentifier('on' + event),
	    t.JSXExpressionContainer(t.ArrowFunctionExpression([t.Identifier('$event')], code))
	  );

	  var props = [valueProp, handlerProp];

	  if (modifier === 'trim' || modifier === 'number') {
	    props.push(
	      t.JSXAttribute(
	        t.JSXIdentifier('onBlur'),
	        t.JSXExpressionContainer(
	          t.ArrowFunctionExpression(
	            [],
	            t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('$forceUpdate')), [])
	          )
	        )
	      )
	    );
	  }

	  return props
	};

	var genComponentModel = function genComponentModel(t, modelAttribute, model, modifier, path, type) {
	  var baseValueExpression = t.Identifier('$$v');
	  var valueExpression = baseValueExpression;

	  if (modifier === 'trim') {
	    valueExpression = t.CallExpression(t.MemberExpression(valueExpression, t.Identifier('trim')), []);
	  } else if (modifier === 'number') {
	    valueExpression = t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_n')), [valueExpression]);
	  }

	  var assignment = genAssignmentCode(t, model, valueExpression);

	  var valueProp = t.JSXAttribute(t.jSXIdentifier('domPropsValue'), t.JSXExpressionContainer(model));

	  var handlerProp = t.JSXAttribute(
	    t.JSXIdentifier('onChange'),
	    t.JSXExpressionContainer(t.ArrowFunctionExpression([baseValueExpression], t.BlockStatement([assignment])))
	  );

	  return [valueProp, handlerProp]
	};

	var babelPluginJsxVModel = function(babel) {
	  var t = babel.types;

	  return {
	    inherits: lib,
	    visitor: {
	      JSXOpeningElement: function JSXOpeningElement(path) {
	        var model = null;
	        var modifier = null;
	        var modelAttribute = null;
	        var type = null;
	        var typePath = null;

	        path.get('attributes').forEach(function(path) {
	          if (!path.node.name) {
	            return
	          }

	          if (path.node.name.name === 'type') {
	            type = path.node.value.value;
	            typePath = path.get('value');
	          }
	          /* istanbul ignore else */
	          if (t.isJSXIdentifier(path.node.name)) {
	            if (path.node.name.name !== 'v-model') {
	              return
	            }
	          } else if (t.isJSXNamespacedName(path.node.name)) {
	            if (path.node.name.namespace.name !== 'v-model') {
	              return
	            }

	            if (!~allowedModifiers.indexOf(path.node.name.name.name)) {
	              throw path
	                .get('name')
	                .get('name')
	                .buildCodeFrameError('v-model does not support "' + path.node.name.name.name + '" modifier')
	            }

	            modifier = path.node.name.name.name;
	          } else {
	            return
	          }

	          modelAttribute = path;

	          if (model) {
	            throw path.buildCodeFrameError('you can not have multiple v-model directives on a single element')
	          }

	          if (!t.isJSXExpressionContainer(path.node.value)) {
	            throw path.get('value').buildCodeFrameError('you should use JSX Expression with v-model')
	          }

	          if (!t.isMemberExpression(path.node.value.expression)) {
	            throw path
	              .get('value')
	              .get('expression')
	              .buildCodeFrameError('you should use MemberExpression with v-model')
	          }

	          model = path.node.value.expression;
	        });

	        if (!model) {
	          return
	        }

	        var tag = path.node.name.name;

	        if (tag === 'input' && typePath && t.isJSXExpressionContainer(typePath.node)) {
	          throw typePath.buildCodeFrameError('you can not use dynamic type with v-model')
	        }
	        if (tag === 'input' && type === 'file') {
	          throw typePath.buildCodeFrameError('you can not use "file" type with v-model')
	        }

	        var replacement = null;

	        if (tag === 'select') {
	          replacement = genSelectModel(t, modelAttribute, model, modifier);
	        } else if (tag === 'input' && type === 'checkbox') {
	          replacement = genCheckboxModel(t, modelAttribute, model, modifier, path);
	        } else if (tag === 'input' && type === 'radio') {
	          replacement = genRadioModel(t, modelAttribute, model, modifier, path);
	        } else if (tag === 'input' || tag === 'textarea') {
	          replacement = genDefaultModel(t, modelAttribute, model, modifier, path, type);
	        } else if (!isReservedTag(tag)) {
	          replacement = genComponentModel(t, modelAttribute, model, modifier, path);
	        } else {
	          throw path.buildCodeFrameError('you can not use "' + tag + '" with v-model')
	        }

	        modelAttribute.replaceWithMultiple([
	          ...replacement,
	          t.JSXSpreadAttribute(
	            t.ObjectExpression([
	              t.ObjectProperty(
	                t.Identifier('directives'),
	                t.ArrayExpression([
	                  t.ObjectExpression([
	                    t.ObjectProperty(t.Identifier('name'), t.StringLiteral('model')),
	                    t.ObjectProperty(t.Identifier('value'), model)
	                  ])
	                ])
	              )
	            ])
	          )
	        ]);
	      }
	    }
	  }
	};

	var index$2 = (function (_) {
	  var _ref = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {},
	      _ref$eventModifiers = _ref.eventModifiers,
	      eventModifiers = _ref$eventModifiers === void 0 ? true : _ref$eventModifiers,
	      _ref$vModel = _ref.vModel,
	      vModel = _ref$vModel === void 0 ? true : _ref$vModel;

	  return {
	    plugins: [eventModifiers && bundle, vModel && babelPluginJsxVModel, babelPluginTransformVueJsx].filter(Boolean)
	  };
	});

	return index$2;

})));
