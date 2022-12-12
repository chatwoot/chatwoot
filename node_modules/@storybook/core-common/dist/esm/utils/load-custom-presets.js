import path from 'path';
import { serverRequire, serverResolve } from './interpret-require';
import { validateConfigurationFiles } from './validate-configuration-files';
export function loadCustomPresets({
  configDir: configDir
}) {
  validateConfigurationFiles(configDir);
  var presets = serverRequire(path.resolve(configDir, 'presets'));
  var main = serverRequire(path.resolve(configDir, 'main'));

  if (main) {
    return [serverResolve(path.resolve(configDir, 'main'))];
  }

  return presets || [];
}