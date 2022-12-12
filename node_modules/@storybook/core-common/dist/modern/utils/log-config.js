/* eslint-disable no-console */
import chalk from 'chalk';
export function logConfig(caption, config) {
  console.log(chalk.cyan(caption));
  console.dir(config, {
    depth: null
  });
}