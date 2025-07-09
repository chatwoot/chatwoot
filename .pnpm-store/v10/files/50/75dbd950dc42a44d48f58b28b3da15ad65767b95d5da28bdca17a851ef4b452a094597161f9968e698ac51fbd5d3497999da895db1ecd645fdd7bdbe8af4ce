
# obj-case

  Work with objects of different cased keys. Anything supported by [nbubna/Case](https://github.com/nbubna/Case). Makes finding and editing objects between languages a little more forgiving while still not modifying the original JSON.

  [![Build Status](https://travis-ci.org/segmentio/obj-case.png?branch=master)](https://travis-ci.org/segmentio/facade)

## Installation

  Install with [component(1)](http://component.io):

    $ component install segmentio/obj-case

## API


### .find(obj, key)

  Returns the value for the object with the given key

  ```javascript
  var obj = { my : { super_cool : { climbingShoes : 'x' }}};
  objCase.find(obj, 'my.superCool.CLIMBING SHOES');  // 'x'
  ```

### .del(obj, key, val, [options])

  Deletes a nested key

  ```javascript
  var obj = { 'a wild' : { mouse : { APPEARED : true }}};
  objCase.del(obj, 'aWild.mouse.appeared');
  console.log(obj); // { 'a wild' : { mouse : {} }}
  ```


### .replace(obj, key, val, [options])

  Replaces a nested key's value

  ```javascript
  var obj = { replacing : { keys : 'is the best' }};
  objCase.replace(obj, 'replacing.keys', 'is just okay');
  console.log(obj) // { replacing : { keys : 'is just okay' }}
  ```


## License

  MIT
