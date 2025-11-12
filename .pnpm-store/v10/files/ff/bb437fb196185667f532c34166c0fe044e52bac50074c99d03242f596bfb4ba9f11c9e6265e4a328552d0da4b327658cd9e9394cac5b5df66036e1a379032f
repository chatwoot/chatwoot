# Changelog

### v0.7.0

- Bidirectional Context (the order of words can now vary, does not increase memory when using bidirectional context)
- New memory-friendly strategy for indexes (switchable, saves up to 50% of memory for each index, slightly decrease performance)
- Better scoring calculation (one of the biggest concerns of the old implementation was that the order of arrays processed in the intersection has affected the order of relevance in the final result)
- Fix resolution (the resolution in the old implementation was not fully stretched through the whole range in some cases)
- Skip words (optionally, automatically skip words from the context chain which are too short)
- Hugely improves performance of long queries (up to 450x faster!) and also memory allocation (up to 250x less memory)
- New fast-update strategy (optionally, hugely improves performance of all updates and removals of indexed contents up to 2850x)
- Improved auto-balanced cache (keep and expire cache by popularity)
- Append contents to already existing entries (already indexed documents or contents)
- New method "contain" to check if an ID was already indexed
- Access documents directly from internal store (read/write)
- Suggestions are hugely improved, falls back from context search all the way down to single term match
- Document descriptor has now array support (optionally adds array entries via the new `append` under the hood to provide a unique relevance context for each entry)
- Document storage handler gets improved
- Results from document index now grouped by field (this is one of the few bigger breaking changes which needs migrations of your old code)
- Boolean search has a new concept (use in combination of the new result structure)
- Node.js Worker Threads
- Improved default latin encoders
- New parallelization model and workload distribution
- Improved Export/Import
- Tag Search
- Offset pagination
- Enhanced Field Search
- Improved sorting by relevance (score)
- Added Context Scoring (context index has its own resolution)
- Enhanced charset normalization
- Improved bundler (support for inline WebWorker)

These features have been removed:

- Where-Clause
- Index Information `index.info()`
- Paging Cursor (was replaced by `offset`)

#### Migration Quick Overview

> The "async" options was removed, instead you can call each method in its async version, e.g. `index.addAsync` or `index.searchAsync`.

> Define document fields as object keys is not longer supported due to the unification of all option payloads.

A full configuration example for a context-based index:

```js
var index = new Index({
    tokenize: "strict",
    resolution: 9,
    minlength: 3,
    optimize: true,
    fastupdate: true,
    cache: 100,
    context: {
        depth: 1,
        resolution: 3,
        bidirectional: true
    }
});
```

The `resolution` could be set also for the contextual index.

A full configuration example for a document based index:

```js
const index = new Document({
    tokenize: "forward",
    optimize: true,
    resolution: 9,
    cache: 100,
    worker: true,
    document: {
        id: "id",
        tag: "tag",
        store: [
            "title", "content"
        ],
        index: [{
            field: "title",
            tokenize: "forward",
            optimize: true,
            resolution: 9
        },{
            field:  "content",
            tokenize: "strict",
            optimize: true,
            resolution: 9,
            minlength: 3,
            context: {
                depth: 1,
                resolution: 3
            }
        }]
    }
});
```

A full configuration example for a document search:

```js
index.search({
    enrich: true,
    bool: "and",
    tag: ["cat", "dog"],
    index: [{
        field: "title",
        query: "some query",
        limit: 100,
        suggest: true
    },{
        field: "content",
        query: "same or other query",
        limit: 100,
        suggest: true
    }]
});
```

#### Where Clause Replacement

Old Syntax:

```js
const result = index.where({
    cat: "comedy",
    year: "2018"
});
```

Equivalent Syntax (0.7.x):

```js
const data = Object.values(index.store);
```

The line above retrieves data from the document store (just useful when not already available in your runtime).

```js
const result = data.filter(function(item){ 
    return item.cat === "comedy" && item.year === "2018";
});
```

Also considering using the <a href="https://github.com/nextapps-de/flexsearch#tags">Tag-Search</a> feature, which partially replaces the Where-Clause with a huge performance boost.

### v0.6.0

- Pagination

### v0.5.3

- Logical Operator

### v0.5.2

- Intersect Partial Results

### v0.5.1

- Customizable Scoring Resolution

### v0.5.0

- Where / Find Documents
- Document Tags
- Custom Sort

### v0.4.0

- Index Documents (Field-Search)

### v0.3.6

- Right-To-Left Support
- CJK Word Splitting Support

### v0.3.5

- Promise Support

### v0.3.4

- Export / Import Indexes (Serialize)

### v0.3.0

- Profiler Support
