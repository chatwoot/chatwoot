<div align="center">
<br>
<br>
<p>
  <img src=".github/mascot.png" style="height: 150px;">
  <h1>pico-search</h1>
</p>
<br>
<br>

![npm](https://img.shields.io/npm/dm/%40scmmishra%2Fpico-search) ![Less than 1KB](https://deno.bundlejs.com/?q=@scmmishra/pico-search&badge)
<br>
![DeepSource](https://deepsource.io/gh/scmmishra/pico-search.svg/?label=active+issues&show_trend=true&token=_HAIDwNbi1ocMhaBKxB_BcSQ)
![DeepSource](https://deepsource.io/gh/scmmishra/pico-search.svg/?label=resolved+issues&show_trend=true&token=_HAIDwNbi1ocMhaBKxB_BcSQ)

</div>

PicoSearch is a lightweight fuzzy search JavaScript library that provides developers with an easy-to-use, efficient way to perform fuzzy searches on arrays of objects. It uses the Jaro-Winkler distance algorithm, and allows for weighting of search keys. PicoSearch is designed to be simple to use and integrate into any project, making it an excellent choice for developers looking for a fast, lightweight search solution.

[Try on CodeSandbox](https://codesandbox.io/s/picosearch-demo-i79btf)

## Installation

```sh
pnpm install @scmmishra/pico-search
```

```sh
npm install @scmmishra/pico-search
```

```sh
yarn add @scmmishra/pico-search
```

## Usage

PicoSearch exposes a single function: `picoSearch()`. This function takes an array of objects, a search term, an array of keys to search against, and an optional algorithm argument. It returns an array of objects that match the search term. You can find the [typedoc here](https://paka.dev/npm/@scmmishra/pico-search/api)

```typescript
import { picoSearch } from "picosearch";

interface Person {
  name: string;
  age: number;
}

const people: Person[] = [
  { name: "Alice", age: 25 },
  { name: "Bob", age: 30 },
  { name: "Charlie", age: 35 },
  { name: "David", age: 40 },
];

const searchTerm = "ali";
const keys = ["name"];

const results = picoSearch(people, searchTerm, keys);
console.log(results); // [{ name: "Alice", age: 25 }]
```

## Options

### Weighted Keys

By default, all keys passed to `picoSearch()` are weighted equally. You can specify a weight for a specific key by passing an object with `name` and `weight` properties instead of a string in the `keys` array.

```typescript
const keys = [{ name: "name", weight: 2 }, "age"];
```

Weights are relative, so a key with a weight of 2 will be considered twice as important as a key with a weight of 1.

### Minimum Distance Threshold

PicoSearch includes a minimum distance threshold to filter out results that are too far from the search term. The default threshold is 0.8, but you can adjust it by changing the value in the if statement at the end of the loop that processes each object.

```typescript
const results = picoSearch(people, searchTerm, keys, {
  threshold: 0.5,
});
```

## Acknowledgements

PicoSearch uses the Jaro-Winkler distance algorithm which was developed by William E. Winkler and Matthew Jaro.

## License

PicoSearch is released under the MIT License. See LICENSE for details.
