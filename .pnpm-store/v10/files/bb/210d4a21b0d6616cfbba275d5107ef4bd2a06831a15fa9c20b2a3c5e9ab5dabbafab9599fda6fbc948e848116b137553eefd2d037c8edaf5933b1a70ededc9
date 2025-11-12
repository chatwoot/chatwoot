import { FormKitTypeDefinition } from '@formkit/core'
import {
  outer,
  boxInner,
  help,
  boxHelp,
  messages,
  message,
  prefix,
  suffix,
  fieldset,
  decorator,
  box,
  icon,
  legend,
  boxOption,
  boxOptions,
  boxWrapper,
  boxLabel,
  options,
  radios,
  $if,
  $extend,
  defaultIcon,
} from '../index.mjs'

/**
 * Input definition for a radio.
 * @public
 */
export const radio: FormKitTypeDefinition = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: outer(
    $if(
      '$options == undefined',
      /**
       * Single radio structure.
       */
      boxWrapper(
        boxInner(prefix(), box(), decorator(icon('decorator')), suffix()),
        $extend(boxLabel('$label'), {
          if: '$label',
        })
      ),
      /**
       * Multi radio structure.
       */
      fieldset(
        legend('$label'),
        help('$help'),
        boxOptions(
          boxOption(
            boxWrapper(
              boxInner(
                prefix(),
                $extend(box(), {
                  bind: '$option.attrs',
                  attrs: {
                    id: '$option.attrs.id',
                    value: '$option.value',
                    checked: '$fns.isChecked($option.value)',
                  },
                }),
                decorator(icon('decorator')),
                suffix()
              ),
              $extend(boxLabel('$option.label'), {
                if: '$option.label',
              })
            ),
            boxHelp('$option.help')
          )
        )
      )
    ),
    // Help text only goes under the input when it is a single.
    $if('$options == undefined && $help', help('$help')),
    messages(message('$message.value'))
  ),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: 'input',
  /**
   * The family of inputs this one belongs too. For example "text" and "email"
   * are both part of the "text" family. This is primary used for styling.
   */
  family: 'box',
  /**
   * An array of extra props to accept for this input.
   */
  props: ['options', 'onValue', 'offValue', 'optionsLoader'],
  /**
   * Additional features that should be added to your input
   */
  features: [options, radios, defaultIcon('decorator', 'radioDecorator')],
  /**
   * The key used to memoize the schema.
   */
  schemaMemoKey: 'qje02tb3gu8',
}
