import path from 'path';
import dedent from 'ts-dedent';
import { getInterpretedFile } from './interpret-files';
export function loadPreviewOrConfigFile({
  configDir: configDir
}) {
  var storybookConfigPath = getInterpretedFile(path.resolve(configDir, 'config'));
  var storybookPreviewPath = getInterpretedFile(path.resolve(configDir, 'preview'));

  if (storybookConfigPath && storybookPreviewPath) {
    throw new Error(dedent`
      You have both a "config.js" and a "preview.js", remove the "config.js" file from your configDir (${path.resolve(configDir, 'config')})`);
  }

  return storybookPreviewPath || storybookConfigPath;
}