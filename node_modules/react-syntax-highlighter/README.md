## React Syntax Highlighter

[![Actions Status](https://github.com/react-syntax-highlighter/react-syntax-highlighter/workflows/Node%20CI/badge.svg)](https://github.com/conorhastings/react-syntax-highlighter/actions)
[![npm](https://img.shields.io/npm/dm/react-syntax-highlighter.svg?style=flat-square)](https://www.npmjs.com/package/react-syntax-highlighter)

<!-- [![codecov](https://codecov.io/gh/conorhastings/react-syntax-highlighter/branch/master/graph/badge.svg)](https://codecov.io/gh/conorhastings/react-syntax-highlighter) -->

Syntax highlighting component for `React` using the seriously super amazing <a href="https://github.com/wooorm/lowlight">lowlight</a> and <a href="https://github.com/wooorm/refractor">refractor</a> by <a href="https://github.com/wooorm">wooorm</a>

Check out a small demo <a href="https://react-syntax-highlighter.github.io/react-syntax-highlighter/demo/">here</a> and see the component in action highlighting the generated test code <a href="https://conorhastings.github.io/redux-test-recorder/demo/">here</a>.

For React Native you can use <a href='https://github.com/conorhastings/react-native-syntax-highlighter'>react-native-syntax-highlighter</a>

### Install

`npm install react-syntax-highlighter --save`

### Why This One?

There are other syntax highlighters for `React` out there so why use this one? The biggest reason is that all the others rely on triggering calls in `componentDidMount` and `componentDidUpdate` to highlight the code block and then insert it in the render function using `dangerouslySetInnerHTML` or just manually altering the DOM with native javascript. This utilizes a syntax tree to dynamically build the virtual dom which allows for updating only the changing DOM instead of completely overwriting it on any change, and because of this it is also using more idiomatic `React` and allows the use of pure function components brought into `React` as of `0.14`.

### Javascript Styles!

One of the biggest pain points for me trying to find a syntax highlighter for my own projects was the need to put a stylesheet tag on my page. I wanted to provide out of the box code styling with my modules without requiring awkward inclusion of another libs stylesheets. The styles in this module are all javascript based, and all styles supported by `highlight.js` have been ported!

I do realize that javascript styles are not for everyone, so you can optionally choose to use css based styles with classNames added to elements by setting the prop `useInlineStyles` to `false` (it defaults to `true`).

### Use

#### props

- `language` - the language to highlight code in. Available options [here for hljs](./AVAILABLE_LANGUAGES_HLJS.MD) and [here for prism](./AVAILABLE_LANGUAGES_PRISM.MD). (pass text to just render plain monospaced text)
- `style` - style object required from styles/hljs or styles/prism directory depending on whether or not you are importing from `react-syntax-highlighter` or `react-syntax-highlighter/prism` directory [here for hljs](./AVAILABLE_STYLES_HLJS.MD). and [here for prism](./AVAILABLE_STYLES_PRISM.MD). `import { style } from 'react-syntax-highlighter/dist/esm/styles/{hljs|prism}'` . Will use default if style is not included.
- `children` - the code to highlight.
- `customStyle` - prop that will be combined with the top level style on the pre tag, styles here will overwrite earlier styles.
- `codeTagProps` - props that will be spread into the `<code>` tag that is the direct parent of the highlighted code elements. Useful for styling/assigning classNames.
- `useInlineStyles` - if this prop is passed in as false, react syntax highlighter will not add style objects to elements, and will instead append classNames. You can then style the code block by using one of the CSS files provided by highlight.js.
- `showLineNumbers` - if this is enabled line numbers will be shown next to the code block.
- `showInlineLineNumbers` - if this is enabled in conjunction with `showLineNumbers`, line numbers will be rendered into each line, which allows line numbers to display properly when using renderers such as <a href="https://github.com/conorhastings/react-syntax-highlighter-virtualized-renderer">react-syntax-highlighter-virtualized-renderer</a>. (This prop will have no effect if `showLineNumbers` is `false`.)
- `startingLineNumber` - if `showLineNumbers` is enabled the line numbering will start from here.
- `lineNumberContainerStyle` - the line numbers container default to appearing to the left with 10px of right padding. You can use this to override those styles.
- `lineNumberStyle` - inline style to be passed to the span wrapping each number. Can be either an object or a function that receives current line number as argument and returns style object.
- `wrapLines` - a boolean value that determines whether or not each line of code should be wrapped in a parent element. defaults to false, when false one can not take action on an element on the line level. You can see an example of what this enables <a href="https://react-syntax-highlighter.github.io/react-syntax-highlighter/demo/diff.html">here</a>
- `wrapLongLines` - boolean to specify whether to style the `<code>` block with `white-space: pre-wrap` or `white-space: pre`. [Demo](https://react-syntax-highlighter.github.io/react-syntax-highlighter/demo/)
- `lineProps` - props to be passed to the span wrapping each line if wrapLines is true. Can be either an object or a function that receives current line number as argument and returns props object.
- `renderer` - an optional custom renderer for rendering lines of code. See <a href="https://github.com/conorhastings/react-syntax-highlighter-virtualized-renderer">here</a> for an example.
- `PreTag` - the element or custom react component to use in place of the default pre tag, the outermost tag of the component (useful for custom renderer not targeting DOM).
- `CodeTag` - the element or custom react component to use in place of the default code tag, the second tag of the component tree (useful for custom renderer not targeting DOM).
- `spread props` pass arbitrary props to pre tag wrapping code.

```js
import SyntaxHighlighter from 'react-syntax-highlighter';
import { docco } from 'react-syntax-highlighter/dist/esm/styles/hljs';
const Component = () => {
  const codeString = '(num) => num + 1';
  return (
    <SyntaxHighlighter language="javascript" style={docco}>
      {codeString}
    </SyntaxHighlighter>
  );
};
```

### Prism

Using <a href="https://github.com/wooorm/refractor">refractor</a> we can use an ast built on languages from Prism.js instead of highlight.js. This is beneficial especially when highlighting jsx, a problem long unsolved by this module. The semantics of use are basically the same although a light mode is not yet supported (though is coming in the future). You can see a demo(with jsx) using Prism(refractor) <a href="https://react-syntax-highlighter.github.io/react-syntax-highlighter/demo/prism.html">here</a>.

```js
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { dark } from 'react-syntax-highlighter/dist/esm/styles/prism';
const Component = () => {
  const codeString = '(num) => num + 1';
  return (
    <SyntaxHighlighter language="javascript" style={dark}>
      {codeString}
    </SyntaxHighlighter>
  );
};
```

### Light Build

React Syntax Highlighter used in the way described above can have a fairly large footprint. For those that desire more control over what exactly they need, there is an option to import a light build. If you choose to use this you will need to specifically import desired languages and register them using the registerLanguage export from the light build. There is also no default style provided.

```js
import { Light as SyntaxHighlighter } from 'react-syntax-highlighter';
import js from 'react-syntax-highlighter/dist/esm/languages/hljs/javascript';
import docco from 'react-syntax-highlighter/dist/esm/styles/hljs/docco';

SyntaxHighlighter.registerLanguage('javascript', js);
```

You can require `PrismLight` from `react-syntax-highlighter` to use the prism light build instead of the standard light build.

```jsx
import { PrismLight as SyntaxHighlighter } from 'react-syntax-highlighter';
import jsx from 'react-syntax-highlighter/dist/esm/languages/prism/jsx';
import prism from 'react-syntax-highlighter/dist/esm/styles/prism/prism';

SyntaxHighlighter.registerLanguage('jsx', jsx);
```

### Async Build

For optimal bundle size for rendering ASAP, there's a async version of prism light & light.
This versions requires you to use a bundler that supports the dynamic import syntax, like webpack.
This will defer loading of refractor (17kb gzipped) & the languages, while code splits are loaded the code will show with line numbers
but without highlighting.

Prism version:

```js
import { PrismAsyncLight as SyntaxHighlighter } from 'react-syntax-highlighter';
```

Highlight version

```js
import { LightAsync as SyntaxHighlighter } from 'react-syntax-highlighter';
```

#### Supported languages

Access via the `supportedLanguages` static field.

```js
SyntaxHighlighter.supportedLanguages;
```

### Built with React Syntax Highlighter

- [mdx-deck](https://github.com/jxnblk/mdx-deck) - MDX-based presentation decks
- [codecrumbs](https://github.com/Bogdan-Lyashenko/codecrumbs) - Learn, design or document codebase by putting breadcrumbs in source code. Live updates, multi-language support, and easy sharing.
- [Spectacle Editor](https://github.com/FormidableLabs/spectacle-editor) - An Electron based app for creating, editing, saving, and publishing Spectacle presentations. With integrated Plotly support.
- [Superset](https://github.com/airbnb/superset) - Superset is a data exploration platform designed to be visual, intuitive, and interactive.
- [Daydream](https://github.com/segmentio/daydream) - A chrome extension to record your actions into a [nightmare](https://github.com/segmentio/nightmare) script
- [CodeDoc](https://github.com/B1naryStudio/CodeDoc) - Electron based application build with React for creating project documentations
- [React Component Demo](https://github.com/conorhastings/react-component-demo) - A React Component To make live editable demos of other React Components.
- [Redux Test Recorder](https://github.com/conorhastings/redux-test-recorder) - a redux middleware to automatically generate tests for reducers through ui interaction. Syntax highlighter used by react plugin.
- [GitPoint](https://github.com/gitpoint/git-point) - GitHub for iOS. Built with React Native. (built using react-native-syntax-highlighter)
- [Yoga Layout Playground](https://yogalayout.com/playground) - generate code for yoga layout in multiple languages
- [Kibana](https://github.com/elastic/kibana) - browser-based analytics and search dashboard for Elasticsearch.
- [Golangci Web](https://github.com/golangci/golangci-web)
- [Storybook Official Addons](https://github.com/storybooks/storybook)
- [Microsoft Fast DNA](https://github.com/Microsoft/fast-dna/)
- [Alibaba Ice](https://github.com/alibaba/ice)
- [Uber BaseUI Docs](https://github.com/uber-web/baseui)
- [React Select Docs](https://github.com/JedWatson/react-select)
- [Auto-layout](https://github.com/0123cf/auto-layout) - use flex layout
- [npmview](https://github.com/pd4d10/npmview) - A web application to view npm package files
- [Static Forms](https://www.staticforms.xyz) - Free HTML forms for your static websites.
- [React DemoTab](https://github.com/mkosir/react-demo-tab) - A React component to easily create demos of other components
- [codeprinter](https://github.com/jaredpetersen/codeprinter) - Print out code easily
- [Neumorphism](https://www.neumorphism.io) - CSS code generator for Soft UI/Neumorphism shadows
- [grape-ui](https://www.grapeui.com) - Component library using styled-system and other open source components.
- [✅ Good Arduino Code](https://goodarduinocode.com) - A curated library of Arduino Coding examples

If your project uses react-syntax-highlighter please send a pr to add!

### License

MIT
