import "core-js/modules/es.promise.js";
import { logger } from '@storybook/node-logger';
import { getDirectoryFromWorkingDir } from '@storybook/core-common';
import chalk from 'chalk';
import express from 'express';
import { pathExists } from 'fs-extra';
import path from 'path';
import favicon from 'serve-favicon';
import dedent from 'ts-dedent';

var defaultFavIcon = require.resolve('@storybook/core-server/public/favicon.ico');

export async function useStatics(router, options) {
  var hasCustomFavicon = false;
  var staticDirs = await options.presets.apply('staticDirs');

  if (staticDirs && options.staticDir) {
    throw new Error(dedent`
      Conflict when trying to read staticDirs:
      * Storybook's configuration option: 'staticDirs'
      * Storybook's CLI flag: '--staticDir' or '-s'
      
      Choose one of them, but not both.
    `);
  }

  var statics = staticDirs ? staticDirs.map(function (dir) {
    return typeof dir === 'string' ? dir : `${dir.from}:${dir.to}`;
  }) : options.staticDir;

  if (statics && statics.length > 0) {
    await Promise.all(statics.map(async function (dir) {
      try {
        var relativeDir = staticDirs ? getDirectoryFromWorkingDir({
          configDir: options.configDir,
          workingDir: process.cwd(),
          directory: dir
        }) : dir;

        var _await$parseStaticDir = await parseStaticDir(relativeDir),
            staticDir = _await$parseStaticDir.staticDir,
            staticPath = _await$parseStaticDir.staticPath,
            targetEndpoint = _await$parseStaticDir.targetEndpoint;

        logger.info(chalk`=> Serving static files from {cyan ${staticDir}} at {cyan ${targetEndpoint}}`);
        router.use(targetEndpoint, express.static(staticPath, {
          index: false
        }));

        if (!hasCustomFavicon && targetEndpoint === '/') {
          var faviconPath = path.join(staticPath, 'favicon.ico');

          if (await pathExists(faviconPath)) {
            hasCustomFavicon = true;
            router.use(favicon(faviconPath));
          }
        }
      } catch (e) {
        logger.warn(e.message);
      }
    }));
  }

  if (!hasCustomFavicon) {
    router.use(favicon(defaultFavIcon));
  }
}
export var parseStaticDir = async function (arg) {
  // Split on last index of ':', for Windows compatibility (e.g. 'C:\some\dir:\foo')
  var lastColonIndex = arg.lastIndexOf(':');
  var isWindowsAbsolute = path.win32.isAbsolute(arg);
  var isWindowsRawDirOnly = isWindowsAbsolute && lastColonIndex === 1; // e.g. 'C:\some\dir'

  var splitIndex = lastColonIndex !== -1 && !isWindowsRawDirOnly ? lastColonIndex : arg.length;
  var targetRaw = arg.substring(splitIndex + 1) || '/';
  var target = targetRaw.split(path.sep).join(path.posix.sep); // Ensure target has forward-slash path

  var rawDir = arg.substring(0, splitIndex);
  var staticDir = path.isAbsolute(rawDir) ? rawDir : `./${rawDir}`;
  var staticPath = path.resolve(staticDir);
  var targetDir = target.replace(/^\/?/, './');
  var targetEndpoint = targetDir.substring(1);

  if (!(await pathExists(staticPath))) {
    throw new Error(dedent(chalk`
        Failed to load static files, no such directory: {cyan ${staticPath}}
        Make sure this directory exists, or omit the {bold -s (--static-dir)} option.
      `));
  }

  return {
    staticDir: staticDir,
    staticPath: staticPath,
    targetDir: targetDir,
    targetEndpoint: targetEndpoint
  };
};