/// <reference types="vitest" />

const isLibraryMode = process.env.BUILD_MODE === 'library';
const isTestMode = process.env.TEST === 'true';
const isStoryMode = process.env.BUILD_MODE === 'story';

let config;
if (isLibraryMode) {
  config = import('./vite.config.lib');
} else if (isTestMode) {
  config = import('./vite.config.test');
} else if (isStoryMode) {
  config = import('./vite.config.dev');
} else {
  config = import('./vite.config.dev');
}

export default config;
