import { Remote } from 'comlink';
import { ESLint } from 'eslint';
import { fixingSpinner } from '../cli/ora.js';
import { SerializableCore } from '../core-worker.js';
import { Undo } from '../core.js';

export async function doFixAction(
  core: Remote<SerializableCore>,
  results: ESLint.LintResult[],
  selectedRuleIds: string[],
): Promise<Undo> {
  const undo = await fixingSpinner(async () => core.applyAutoFixes(results, selectedRuleIds));
  return undo;
}
