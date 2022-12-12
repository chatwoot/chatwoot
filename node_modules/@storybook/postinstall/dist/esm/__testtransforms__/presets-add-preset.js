import { addPreset } from '../presets';
export default function transformer(file, api) {
  var j = api.jscodeshift;
  var root = j(file.source);
  addPreset('test', null, {
    root: root,
    api: api
  });
  return root.toSource({
    quote: 'single'
  });
}