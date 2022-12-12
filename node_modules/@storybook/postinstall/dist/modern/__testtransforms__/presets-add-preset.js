import { addPreset } from '../presets';
export default function transformer(file, api) {
  const j = api.jscodeshift;
  const root = j(file.source);
  addPreset('test', null, {
    root,
    api
  });
  return root.toSource({
    quote: 'single'
  });
}