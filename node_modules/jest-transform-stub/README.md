# jest-transform-stub

Jest doesn't handle non JavaScript assets by default.

You can use this module to avoid errors when importing non JavaScript assets.

## Usage

```shell
npm install --save-dev jest-transform-stub
```

In your Jest config, add jest-transform-stub to transform non JavaScript assets you want to stub:

```js
{
  "jest": {
    // ..
    "transform": {
      "^.+\\.js$": "babel-jest",
      ".+\\.(css|styl|less|sass|scss|png|jpg|ttf|woff|woff2)$": "jest-transform-stub"
    }
  }
}
```

## FAQ

**My module isn't being transformed**

Jest doesn't apply transforms to node_modules by default. You can solve this by using `moduleNameMapper`:

```js
{
  "jest": {
    // ..
    "moduleNameMapper": {
      "^.+.(css|styl|less|sass|scss|png|jpg|ttf|woff|woff2)$": "jest-transform-stub"
    }
  }
}
```
