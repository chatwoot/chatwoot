import path from 'path';
import { serverRequire } from './interpret-require';
import { validateConfigurationFiles } from './validate-configuration-files';
export function loadMainConfig({
  configDir: configDir
}) {
  validateConfigurationFiles(configDir);
  return serverRequire(path.resolve(configDir, 'main'));
}