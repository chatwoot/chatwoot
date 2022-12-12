import { addPreset } from '../presets';
export default function transformer(file, api) {
  const j = api.jscodeshift;
  const root = j(file.source);
  const options = {
    a: [1, 2, 3],
    b: {
      foo: 'bar'
    },
    c: 'baz'
  };
  addPreset('test', options, {
    root,
    api
  });
  return root.toSource({
    quote: 'single'
  });
}