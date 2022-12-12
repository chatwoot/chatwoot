# file-system-cache
[![Build Status](https://travis-ci.org/philcockfield/file-system-cache.svg)](https://travis-ci.org/philcockfield/file-system-cache)

A super-fast, promise-based cache that reads and writes to the file-system.


## Installation

    npm install --save file-system-cache

## Usage (API)

Create an instance of the cache optionally giving it a folder location to store files within.

```js
import Cache from "file-system-cache";

const cache = Cache({
  basePath: "./.cache", // Optional. Path where cache files are stored (default).
  ns: "my-namespace" // Optional. A grouping namespace for items.
});
```

The optional `ns` ("namespace") allows for multiple groupings of files to reside within the one cache folder.  When you have multiple caches with different namespaces you can re-use the same keys and they will not collide.


#### get(key, defaultValue)
Retrieves the contents of a cached file.

```js
cache.get("foo")
  .then(result => /* Success */)
  .catch(err => /* Fail */);
```

Use `getSync` for a synchronous version.  Pass a `defaultValue` parameter to have that value returned if nothing exists within the cache.


#### set(key, value)
Write a value to the cache.

```js
cache.set("foo", "...value...")
  .then(result => /* Success */)
```

Value types are stored and respected on subsequent calls to `get`.  For examples, passing in Object will return that in it's parsed object state.

Use `setSync` for a synchronous version.


#### remove(key)
Deletes the specified cache item from the file-system.
```js
cache.remove("foo")
  .then(() => /* Removed */)
```

#### clear()
Clears all cached items from the file-system.
```js
cache.clear()
  .then(() => /* All items deleted */)
```


#### save()
Saves (sets) several items to the cache in one operation.
```js
cache.save([{ key:"one", value:"hello" }, { key:"two", value:222 }])
  .then(result => /* All items saved. */)
```

#### load()
Loads all files within the cache's namespace.
```js
cache.load()
  .then(result => /* The complete of cached files (for the ns). */)
```



## Test
    # Run tests.
    npm test

    # Watch and re-run tests.
    npm run tdd
