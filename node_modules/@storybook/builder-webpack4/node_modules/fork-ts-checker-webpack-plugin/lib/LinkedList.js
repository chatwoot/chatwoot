"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var HeadNode = /** @class */ (function () {
    function HeadNode() {
        // eslint-disable-next-line @typescript-eslint/no-use-before-define
        this.next = new TailNode(this);
    }
    return HeadNode;
}());
exports.HeadNode = HeadNode;
var TailNode = /** @class */ (function () {
    function TailNode(head) {
        this.previous = head;
    }
    return TailNode;
}());
exports.TailNode = TailNode;
var LinkedListNode = /** @class */ (function () {
    function LinkedListNode(item) {
        this.next = null;
        this.previous = null;
        this.item = item;
    }
    LinkedListNode.prototype.detachSelf = function () {
        if (!this.next && !this.previous) {
            throw new Error('node is not attached');
        }
        if (this.next) {
            this.next.previous = this.previous;
        }
        if (this.previous) {
            this.previous.next = this.next;
        }
        this.next = null;
        this.previous = null;
    };
    LinkedListNode.prototype.attachAfter = function (node) {
        if (this.next || this.previous) {
            throw new Error('Node is inserted elsewhere');
        }
        this.next = node.next;
        this.previous = node;
        if (node.next) {
            node.next.previous = this;
        }
        node.next = this;
    };
    LinkedListNode.prototype.attachBefore = function (node) {
        if (!node.previous) {
            throw new Error('no previous node found.');
        }
        this.attachAfter(node.previous);
    };
    return LinkedListNode;
}());
exports.LinkedListNode = LinkedListNode;
var LinkedList = /** @class */ (function () {
    function LinkedList() {
        this.head = new HeadNode();
        this.tail = this.head.next;
    }
    LinkedList.prototype.add = function (item) {
        var newNode = new LinkedListNode(item);
        newNode.attachAfter(this.tail.previous);
        return newNode;
    };
    LinkedList.prototype.getItems = function () {
        var result = [];
        this.forEach(function (item) {
            result.push(item);
        });
        return result;
    };
    LinkedList.prototype.forEach = function (callback) {
        var current = this.head.next;
        while (current !== this.tail) {
            // if item is not tail it is always a node
            var item = current;
            callback(item.item, item);
            if (!item.next) {
                throw new Error('badly attached item found.');
            }
            current = item.next;
        }
    };
    LinkedList.prototype.hasItems = function () {
        return this.head.next !== this.tail;
    };
    LinkedList.prototype.getLastItem = function () {
        if (!this.hasItems()) {
            throw new Error('no items in list.');
        }
        return this.head.next;
    };
    return LinkedList;
}());
exports.LinkedList = LinkedList;
//# sourceMappingURL=LinkedList.js.map