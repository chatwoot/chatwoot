import { addPreset } from '../presets';
export default function transformer(file, api) {
  var j = api.jscodeshift;
  var root = j(file.source);
  var options = {
    a: [1, 2, 3],
    b: {
      foo: 'bar'
    },
    c: 'baz'
  };
  addPreset('test', options, {
    root: root,
    api: api
  });
  return root.toSource({
    quote: 'single'
  });
}