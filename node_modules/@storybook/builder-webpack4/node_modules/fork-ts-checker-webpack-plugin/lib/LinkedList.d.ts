export declare class HeadNode<T> {
    next: LinkedListNode<T> | TailNode<T>;
    constructor();
}
export declare class TailNode<T> {
    previous: LinkedListNode<T> | HeadNode<T>;
    constructor(head: HeadNode<T>);
}
export declare class LinkedListNode<T> {
    next: LinkedListNode<T> | TailNode<T> | null;
    previous: LinkedListNode<T> | HeadNode<T> | null;
    readonly item: T;
    constructor(item: T);
    detachSelf(): void;
    attachAfter(node: LinkedListNode<T> | HeadNode<T>): void;
    attachBefore(node: LinkedListNode<T> | TailNode<T>): void;
}
export declare class LinkedList<T> {
    head: HeadNode<T>;
    tail: TailNode<T>;
    constructor();
    add(item: T): LinkedListNode<T>;
    getItems(): T[];
    forEach(callback: (item: T, node: LinkedListNode<T>) => void): void;
    hasItems(): boolean;
    getLastItem(): LinkedListNode<T>;
}
