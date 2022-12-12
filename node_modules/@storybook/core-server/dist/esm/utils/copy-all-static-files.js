import "core-js/modules/es.promise.js";
import chalk from 'chalk';
import fs from 'fs-extra';
import path from 'path';
import { logger } from '@storybook/node-logger';
import { getDirectoryFromWorkingDir } from '@storybook/core-common';
import { parseStaticDir } from './server-statics';
export async function copyAllStaticFiles(staticDirs, outputDir) {
  if (staticDirs && staticDirs.length > 0) {
    await Promise.all(staticDirs.map(async function (dir) {
      try {
        var _await$parseStaticDir = await parseStaticDir(dir),
            staticDir = _await$parseStaticDir.staticDir,
            staticPath = _await$parseStaticDir.staticPath,
            targetDir = _await$parseStaticDir.targetDir;

        var targetPath = path.join(outputDir, targetDir);
        logger.info(chalk`=> Copying static files: {cyan ${staticDir}} => {cyan ${targetDir}}`); // Storybook's own files should not be overwritten, so we skip such files if we find them

        var skipPaths = ['index.html', 'iframe.html'].map(function (f) {
          return path.join(targetPath, f);
        });
        await fs.copy(staticPath, targetPath, {
          dereference: true,
          preserveTimestamps: true,
          filter: function (_, dest) {
            return !skipPaths.includes(dest);
          }
        });
      } catch (e) {
        logger.error(e.message);
        process.exit(-1);
      }
    }));
  }
}
export async function copyAllStaticFilesRelativeToMain(staticDirs, outputDir, configDir) {
  staticDirs.forEach(async function (dir) {
    var staticDirAndTarget = typeof dir === 'string' ? dir : `${dir.from}:${dir.to}`;

    var _await$parseStaticDir2 = await parseStaticDir(getDirectoryFromWorkingDir({
      configDir: configDir,
      workingDir: process.cwd(),
      directory: staticDirAndTarget
    })),
        from = _await$parseStaticDir2.staticPath,
        to = _await$parseStaticDir2.targetEndpoint;

    var targetPath = path.join(outputDir, to);
    var skipPaths = ['index.html', 'iframe.html'].map(function (f) {
      return path.join(targetPath, f);
    });
    logger.info(chalk`=> Copying static files: {cyan ${from}} at {cyan ${targetPath}}`);
    await fs.copy(from, targetPath, {
      dereference: true,
      preserveTimestamps: true,
      filter: function (_, dest) {
        return !skipPaths.includes(dest);
      }
    });
  });
}