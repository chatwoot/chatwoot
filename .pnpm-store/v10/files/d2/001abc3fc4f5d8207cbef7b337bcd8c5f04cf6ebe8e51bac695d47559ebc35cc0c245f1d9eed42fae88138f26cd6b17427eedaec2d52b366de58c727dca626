import { FormKitTypeDefinition } from '@formkit/core'
import {
  outer,
  inner,
  wrapper,
  label,
  help,
  messages,
  message,
  prefix,
  suffix,
  icon,
  selectInput,
  option,
  optionSlot,
  optGroup,
  $if,
  options,
  selects,
  defaultIcon,
} from '../index.mjs'

/**
 * Input definition for a select.
 * @public
 */
export const select: FormKitTypeDefinition = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: outer(
    wrapper(
      label('$label'),
      inner(
        icon('prefix'),
        prefix(),
        selectInput(
          $if(
            '$slots.default',
            () => '$slots.default',
            optionSlot(
              $if(
                '$option.group',
                optGroup(optionSlot(option('$option.label'))),
                option('$option.label')
              )
            )
          )
        ),
        $if('$attrs.multiple !== undefined', () => '', icon('select')),
        suffix(),
        icon('suffix')
      )
    ),
    help('$help'),
    messages(message('$message.value'))
  ),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: 'input',
  /**
   * An array of extra props to accept for this input.
   */
  props: ['options', 'placeholder', 'optionsLoader'],
  /**
   * Additional features that should be added to your input
   */
  features: [options, selects, defaultIcon('select', 'select')],
  /**
   * The key used to memoize the schema.
   */
  schemaMemoKey: 'cb119h43krg',
}
