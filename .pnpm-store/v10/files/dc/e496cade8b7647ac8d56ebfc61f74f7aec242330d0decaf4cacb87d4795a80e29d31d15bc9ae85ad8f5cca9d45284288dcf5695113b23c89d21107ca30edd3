import { access, mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';
import { Remote } from 'comlink';
import { ESLint } from 'eslint';
import { fixingSpinner } from '../cli/ora.js';
import { promptToInputReuseFilterScript } from '../cli/prompt.js';
import { SerializableCore } from '../core-worker.js';
import { Undo } from '../core.js';
import {
  editFileWithEditor,
  generateExampleFilterScriptFilePath,
  generateFilterScriptFilePath,
} from '../util/filter-script.js';

export async function doApplySuggestionsAction(
  core: Remote<SerializableCore>,
  results: ESLint.LintResult[],
  selectedRuleIds: string[],
): Promise<Undo> {
  const exampleScript = await readFile(generateExampleFilterScriptFilePath(), 'utf8');
  const filterScriptFilePath = generateFilterScriptFilePath(selectedRuleIds);
  const isFilterScriptExist = await access(filterScriptFilePath)
    .then(() => true)
    .catch(() => false);
  if (isFilterScriptExist) {
    const reuseFilterScript = await promptToInputReuseFilterScript();
    if (!reuseFilterScript) {
      await writeFile(filterScriptFilePath, exampleScript);
    }
  } else {
    // ディレクトリがない可能性を考慮して作成しておく
    await mkdir(dirname(filterScriptFilePath), { recursive: true });
    await writeFile(filterScriptFilePath, exampleScript);
  }
  console.log('Opening editor...');

  const filterScript = await editFileWithEditor(filterScriptFilePath);
  const undo = await fixingSpinner(async () => core.applySuggestions(results, selectedRuleIds, filterScript));
  return undo;
}
