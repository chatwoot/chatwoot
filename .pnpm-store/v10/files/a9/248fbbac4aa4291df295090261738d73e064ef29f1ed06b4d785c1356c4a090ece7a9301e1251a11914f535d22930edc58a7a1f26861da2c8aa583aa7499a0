import {
  outer,
  wrapper,
  help,
  messages,
  message,
  icon,
  prefix,
  suffix,
  buttonInput,
  buttonLabel,
  localize,
  ignores,
} from '../index.mjs'
/**
 * Input definition for a button.
 * @public
 */
export const button = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: outer(
    messages(message('$message.value')),
    wrapper(
      buttonInput(
        icon('prefix'),
        prefix(),
        buttonLabel('$label || $ui.submit.value'),
        suffix(),
        icon('suffix')
      )
    ),
    help('$help')
  ),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: 'input',
  /**
   * The family of inputs this one belongs too. For example "text" and "email"
   * are both part of the "text" family. This is primary used for styling.
   */
  family: 'button',
  /**
   * An array of extra props to accept for this input.
   */
  props: [],
  /**
   * Additional features that should be added to your input
   */
  features: [localize('submit'), ignores],
  /**
   * A key to use for memoizing the schema. This is used to prevent the schema
   * from needing to be stringified when performing a memo lookup.
   */
  schemaMemoKey: 'h6st4epl3j8',
}
