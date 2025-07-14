import { Rule } from 'eslint';
import { notEmpty } from '../util/type-check.js';
import { FixContext } from './index.js';

// eslint-disable-next-line @typescript-eslint/ban-types
export type FixToApplyAutoFixesArgs = {};

/**
 * Create fix to apply auto-fixes.
 */
export function createFixToApplyAutoFixes(context: FixContext, _args: FixToApplyAutoFixesArgs): Rule.Fix[] {
  return context.messages.map((message) => message.fix).filter(notEmpty);
}
