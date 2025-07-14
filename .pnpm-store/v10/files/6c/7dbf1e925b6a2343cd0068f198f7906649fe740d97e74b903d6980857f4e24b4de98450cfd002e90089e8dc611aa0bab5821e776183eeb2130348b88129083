# OrderedMap

Persistent data structure representing an ordered mapping from strings
to values, with some convenient update methods.

This is not an efficient data structure for large maps, just a minimal
helper for cleanly creating and managing small maps in a way that
makes their key order explicit and easy to think about.

License: MIT

## Reference

The exported value from this module is the class `OrderedMap`,
instances of which represent a mapping from strings to arbitrary
values.

**`OrderedMap.from`**`(value: ?Object | OrderedMap) → OrderedMap`  
Return a map with the given content. If null, create an empty map. If
given an ordered map, return that map itself. If given an object,
create a map from the object's properties.

### Methods

Instances of `OrderedMap` have the following methods and properties:

**`get`**`(key: string) → ?any`  
Retrieve the value stored under `key`, or return undefined when
no such key exists.

**`update`**`(key: string, value: any, newKey: ?string) → OrderedMap`  
Create a new map by replacing the value of `key` with a new
value, or adding a binding to the end of the map. If `newKey` is
given, the key of the binding will be replaced with that key.

**`remove`**`(key: string) → OrderedMap`  
Return a map with the given key removed, if it existed.

**`addToStart`**`(key: string, value: any) → OrderedMap`  
Add a new key to the start of the map.

**`addToEnd`**`(key: string, value: any) → OrderedMap`  
Add a new key to the end of the map.

**`addBefore`**`(place: string, key: value: string, value: any) → OrderedMap`  
Add a key after the given key. If `place` is not found, the new
key is added to the end.

**`forEach`**`(f: (key: string, value: any))`  
Call the given function for each key/value pair in the map, in
order.

**`prepend`**`(map: Object | OrderedMap) → OrderedMap`  
Create a new map by prepending the keys in this map that don't
appear in `map` before the keys in `map`.

**`append`**`(map: Object | OrderedMap) → OrderedMap`  
Create a new map by appending the keys in this map that don't
appear in `map` after the keys in `map`.

**`subtract`**`(map: Object | OrderedMap) → OrderedMap`  
Create a map containing all the keys in this map that don't
appear in `map`.

**`size`**`: number`  
The amount of keys in this map.
