import { Remote } from 'comlink';
import { ESLint } from 'eslint';
import { fixingSpinner } from '../cli/ora.js';
import { DescriptionPosition, promptToInputDescription, promptToInputDescriptionPosition } from '../cli/prompt.js';
import { SerializableCore } from '../core-worker.js';
import { Undo } from '../core.js';

export async function doDisablePerLineAction(
  core: Remote<SerializableCore>,
  results: ESLint.LintResult[],
  selectedRuleIds: string[],
): Promise<Undo> {
  const description = await promptToInputDescription();
  let descriptionPosition: DescriptionPosition;
  if (description) {
    descriptionPosition = await promptToInputDescriptionPosition();
  }
  const undo = await fixingSpinner(async () =>
    core.disablePerLine(results, selectedRuleIds, description, descriptionPosition),
  );
  return undo;
}
