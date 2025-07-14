import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Worker } from 'node:worker_threads';
import { wrap } from 'comlink';
import nodeEndpoint from 'comlink/dist/esm/node-adapter.mjs';
import isInstalledGlobally from 'is-installed-globally';
import terminalLink from 'terminal-link';
import { warn } from '../cli/log.js';
import { parseArgv } from '../cli/parse-argv.js';
import { translateCLIOptions } from '../config.js';
import { shouldUseFlatConfig } from '../eslint/use-at-your-own-risk.js';
import { lint, selectAction, selectRuleIds, checkResults } from '../scene/index.js';
/**
 * Run eslint-interactive.
 */
export async function run(options) {
    if (isInstalledGlobally) {
        warn('eslint-interactive is installed globally. ' +
            'The globally installed eslint-interactive is not officially supported because some features do not work. ' +
            'It is recommended to install eslint-interactive locally.');
    }
    const parsedCLIOptions = parseArgv(options.argv);
    const usingFlatConfig = await shouldUseFlatConfig();
    const config = translateCLIOptions(parsedCLIOptions, usingFlatConfig ? 'flat' : 'eslintrc');
    // Directly executing the Core API will hog the main thread and halt the spinner.
    // So we wrap it with comlink and run it on the Worker.
    const worker = new Worker(join(dirname(fileURLToPath(import.meta.url)), '..', 'core-worker.js'), {
        env: {
            ...process.env,
            // NOTE:
            // - `terminal-link` uses `supports-hyperlinks` and `supports-color` to determine if a terminal that supports hyperlinks is in use.
            // - If the terminal does not support hyperlinks, it will fallback to not print the link.
            // - However, due to the specifications of Node.js, the decision does not work well on worker_threads.
            // - So here we use a special environment variable to force the printing mode to be switched.
            // ref: https://github.com/chalk/supports-color/issues/97, https://github.com/nodejs/node/issues/26946
            FORCE_HYPERLINK: terminalLink.isSupported ? '1' : '0',
        },
        // NOTE: Pass CLI options (--unhandled-rejections=strict, etc.) to the worker
        execArgv: process.execArgv,
    });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const ProxiedCore = wrap(nodeEndpoint(worker));
    const core = await new ProxiedCore(config);
    let nextScene = { name: 'lint' };
    while (nextScene.name !== 'exit') {
        if (nextScene.name === 'lint') {
            // eslint-disable-next-line no-await-in-loop
            nextScene = await lint(core);
        }
        else if (nextScene.name === 'selectRuleIds') {
            // eslint-disable-next-line no-await-in-loop
            nextScene = await selectRuleIds(core, nextScene.args);
        }
        else if (nextScene.name === 'selectAction') {
            // eslint-disable-next-line no-await-in-loop
            nextScene = await selectAction(core, nextScene.args);
        }
        else if (nextScene.name === 'checkResults') {
            // eslint-disable-next-line no-await-in-loop
            nextScene = await checkResults(nextScene.args);
        }
    }
    await worker.terminate();
}
//# sourceMappingURL=run.js.map