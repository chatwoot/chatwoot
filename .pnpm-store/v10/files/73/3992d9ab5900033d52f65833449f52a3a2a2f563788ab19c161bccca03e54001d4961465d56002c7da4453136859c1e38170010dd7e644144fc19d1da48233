import { fragment, disablesChildren, renamesRadios } from '../index.mjs'
/**
 * Input definition for a group.
 * @public
 */
export const group = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: fragment('$slots.default'),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: 'group',
  /**
   * An array of extra props to accept for this input.
   */
  props: [],
  /**
   * Additional features that should be added to your input
   */
  features: [disablesChildren, renamesRadios],
}
