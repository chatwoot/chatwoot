import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.string.trim.js";
import path from 'path';
import { execSync } from 'child_process';
import { getProjectRoot } from '@storybook/core-common';
import { oneWayHash } from './one-way-hash';
var anonymousProjectId;
export var getAnonymousProjectId = function getAnonymousProjectId() {
  if (anonymousProjectId) {
    return anonymousProjectId;
  }

  var unhashedProjectId;

  try {
    var projectRoot = getProjectRoot();
    var projectRootPath = path.relative(projectRoot, process.cwd());
    var originBuffer = execSync("git config --local --get remote.origin.url", {
      timeout: 1000,
      stdio: "pipe"
    }); // we use a combination of remoteUrl and working directory
    // to separate multiple storybooks from the same project (e.g. monorepo)

    unhashedProjectId = "".concat(String(originBuffer).trim()).concat(projectRootPath);
    anonymousProjectId = oneWayHash(unhashedProjectId);
  } catch (_) {//
  }

  return anonymousProjectId;
};