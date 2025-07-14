// @ts-check

// Edit this file to customize how  you want to convert `Linter.LintMessage` to `Rule.Fix`.
// Save and close this file to run `eslint --fix`.

/**
 * A function to convert `Linter.LintMessage` to `Rule.Fix`.
 * @param {import('eslint').Linter.LintMessage} message - The `Linter.LintMessage` to be converted.
 * @param {import('estree').Node | null} node - The node corresponding to the message.
 * @param {import('eslint-interactive').FixContext} context - The context of the fix.
 * @returns {import('eslint').Rule.Fix | null | undefined} The `Rule.Fix` converted from `Linter.LintMessage`. If null or undefined, the message is not fixable.
 */
function fixableMaker(message, node, context) {
  // example:

  console.log(context.filename);

  // Edge case handling
  if (!node) return null;
  if (!node.range) return null;

  if (message.ruleId === 'no-unused-vars' || message.ruleId === '@typescript-eslint/no-unused-vars') {
    // Add underscores to the head of unused variable names.
    // target codes: https://astexplorer.net/#/gist/e33d44d2e69a733766abbc9706fd3ed5/169a615afba7b0d5c88e87894db93fc7346250d2

    if (node.type !== 'Identifier') return null;
    // For more information about the fixer API, see the following:
    // https://eslint.org/docs/developer-guide/working-with-rules#applying-fixes
    return context.fixer.insertTextBefore(node, '_');
  } else {
    return null;
  }
}

// Here, `fixableMaker` is passed to eslint-interactive pass.
// NOTE: The value evaluated on the last line of the file will be passed to eslint-interactive.
// This is because eslint-interactive evaluates this file with `eval`.
fixableMaker;
