import { writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { stripVTControlCharacters } from 'node:util';
import chalk from 'chalk';
import { pager } from '../cli/pager.js';
import { promptToInputDisplayMode } from '../cli/prompt.js';
import { getCacheDir } from '../util/cache.js';
import { unreachable } from '../util/type-check.js';
export async function doPrintResultDetailsAction(core, results, selectedRuleIds) {
    const displayMode = await promptToInputDisplayMode();
    const formattedResultDetails = await core.formatResultDetails(results, selectedRuleIds);
    if (displayMode === 'printInTerminal') {
        console.log(formattedResultDetails);
    }
    else if (displayMode === 'printInTerminalWithPager') {
        await pager(formattedResultDetails);
    }
    else if (displayMode === 'writeToFile') {
        const filePath = join(getCacheDir(), 'lint-result-details.txt');
        await writeFile(filePath, stripVTControlCharacters(formattedResultDetails), 'utf8');
        console.log(chalk.cyan(`Wrote to ${filePath}`));
    }
    else {
        // eslint-disable-next-line @typescript-eslint/restrict-template-expressions
        unreachable(`Unknown display mode: ${displayMode}`);
    }
}
//# sourceMappingURL=print-result-details.js.map