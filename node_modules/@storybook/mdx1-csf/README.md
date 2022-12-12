## @storybook/mdx1-csf

Storybook's `mdx1-csf` is a compiler that turns MDXv1 input into CSF output.

For example, the following input:

```mdx
import { Meta, Story } from '@storybook/addon-docs';

<Meta title="atoms/Button" />

<Story name="Bar">
  <Button>hello</Button>
</Story>
```

Might be transformed into the following CSF (over-simplified):

```js
export default {
  title: 'atoms/Button',
};

export const Bar = () => <Button>hello</Button>;
```

## API

This library exports three functions to compile MDX: `compile`, `compileSync`, and `createCompiler`.

### compile

Asynchronously compile a string:

```js
const code = '# hello\n\nworld';
const output = await compile(code);
```

### compileSync

Synchronously compile a string:

```js
const code = '# hello\n\nworld';
const output = compileSync(code);
```

### createCompiler

Create a compiler plugin for for MDXv1:

```js
import mdx from '@mdx-js/mdx';
import { createCompiler } from '@storybook/mdx1-csf';

const code = '# hello\n\nworld';
mdx.sync(code, { compilers: [createCompiler()] });
```

## Contributing

We welcome contributions to Storybook!

- 📥 Pull requests and 🌟 Stars are always welcome.
- Read our [contributing guide](CONTRIBUTING.md) to get started,
  or find us on [Discord](https://discord.gg/storybook), we will take the time to guide you

## License

[MIT](https://github.com/storybookjs/csf-mdx1/blob/main/LICENSE)
