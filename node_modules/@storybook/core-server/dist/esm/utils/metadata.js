import "core-js/modules/es.promise.js";
import fs from 'fs-extra';
import { getStorybookMetadata } from '@storybook/telemetry';
export async function extractStorybookMetadata(outputFile, configDir) {
  var storybookMetadata = await getStorybookMetadata(configDir);
  await fs.writeJson(outputFile, storybookMetadata);
}
export function useStorybookMetadata(router, configDir) {
  router.use('/project.json', async function (req, res) {
    var storybookMetadata = await getStorybookMetadata(configDir);
    res.header('Content-Type', 'application/json');
    res.send(JSON.stringify(storybookMetadata));
  });
}