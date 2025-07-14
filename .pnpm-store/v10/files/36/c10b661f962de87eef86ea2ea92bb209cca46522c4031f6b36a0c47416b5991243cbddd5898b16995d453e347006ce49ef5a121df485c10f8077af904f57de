// https://medium.com/dsinjs/implementing-lru-cache-in-javascript-94ba6755cda9

class Node {
  constructor(key, value, next = null, prev = null) {
    this.key = key;
    this.value = value;
    this.next = next;
    this.prev = prev;
  }
}

export default class LRUCache {
  //set default limit of 10 if limit is not passed.
  constructor(limit = 10) {
    this.size = 0;
    this.limit = limit;
    this.head = null;
    this.tail = null;
    this.cache = {};
  }

  // Write Node to head of LinkedList
  // update cache with Node key and Node reference
  put(key, value){
    this.ensureLimit();

    if(!this.head){
      this.head = this.tail = new Node(key, value);
    }else{
      const node = new Node(key, value, this.head);
      this.head.prev = node;
      this.head = node;
    }

    //Update the cache map
    this.cache[key] = this.head;
    this.size++;
  }

  // Read from cache map and make that node as new Head of LinkedList
  get(key){
    if(this.cache[key]){
      const value = this.cache[key].value;

      // node removed from it's position and cache
      this.remove(key)
      // write node again to the head of LinkedList to make it most recently used
      this.put(key, value);

      return value;
    }

    console.log(`Item not available in cache for key ${key}`);
  }

  ensureLimit(){
    if(this.size === this.limit){
      this.remove(this.tail.key)
    }
  }

  remove(key){
    const node = this.cache[key];

    if(node.prev !== null){
      node.prev.next = node.next;
    }else{
      this.head = node.next;
    }

    if(node.next !== null){
      node.next.prev = node.prev;
    }else{
      this.tail = node.prev
    }

    delete this.cache[key];
    this.size--;
  }

  clear() {
    this.head = null;
    this.tail = null;
    this.size = 0;
    this.cache = {};
  }

  // // Invokes the callback function with every node of the chain and the index of the node.
  // forEach(fn) {
  //   let node = this.head;
  //   let counter = 0;
  //   while (node) {
  //     fn(node, counter);
  //     node = node.next;
  //     counter++;
  //   }
  // }

  // // To iterate over LRU with a 'for...of' loop
  // *[Symbol.iterator]() {
  //   let node = this.head;
  //   while (node) {
  //     yield node;
  //     node = node.next;
  //   }
  // }
}