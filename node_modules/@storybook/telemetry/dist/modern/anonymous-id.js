import path from 'path';
import { execSync } from 'child_process';
import { getProjectRoot } from '@storybook/core-common';
import { oneWayHash } from './one-way-hash';
let anonymousProjectId;
export const getAnonymousProjectId = () => {
  if (anonymousProjectId) {
    return anonymousProjectId;
  }

  let unhashedProjectId;

  try {
    const projectRoot = getProjectRoot();
    const projectRootPath = path.relative(projectRoot, process.cwd());
    const originBuffer = execSync(`git config --local --get remote.origin.url`, {
      timeout: 1000,
      stdio: `pipe`
    }); // we use a combination of remoteUrl and working directory
    // to separate multiple storybooks from the same project (e.g. monorepo)

    unhashedProjectId = `${String(originBuffer).trim()}${projectRootPath}`;
    anonymousProjectId = oneWayHash(unhashedProjectId);
  } catch (_) {//
  }

  return anonymousProjectId;
};