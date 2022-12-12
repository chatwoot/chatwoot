# Map Or Similar
Returns a JavaScript Map() or a similar object with the same interface, if Map is not available.
Focuses on performance.
No dependencies.
Made for the browser and nodejs.

## Install
```javascript
npm install map-or-similar --save
```

## Use
```javascript
var MapOrSimilar = require('map-or-similar');

// make a new map or similar object
var myMap = new MapOrSimilar();

// use it like a map
myMap.set('key1', 'value1');
myMap.set({ val: 'complex object as key' }, 'value2');
```

The following methods and properties are supported identically to Map():

```Slim
set(key, val)     : Sets a value to a key. Key can be a complex object, array, etc.
get(key)          : Returns the value of a key.
has(key)          : Returns true if the key exists, otherwise false.
delete(key)       : Deletes a key and its value.
forEach(callback) : Invokes callback(val, key, object) once for each key-value pair in insertion order.
size              : Returns the number of keys-value pairs.
```

Does not support other Map methods or properties.

## Test
```javascript
npm run test
```

## License

Released under an MIT license.

### Other Libs

- [Memoizerific](https://github.com/thinkloop/memoizerific): Fastest, smallest, most-efficient JavaScript memoization lib to memoize JS functions.
- [Multi Key Cache](https://github.com/thinkloop/multi-key-cache): A JavaScript (JS) cache that can have multiple complex values as keys.
