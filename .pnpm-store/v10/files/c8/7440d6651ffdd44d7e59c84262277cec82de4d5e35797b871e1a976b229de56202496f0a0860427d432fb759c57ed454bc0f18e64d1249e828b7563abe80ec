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
  fileInput,
  fileItem,
  fileList,
  fileName,
  fileRemove,
  noFiles,
  files,
  $if,
  defaultIcon,
} from '../index.mjs'

/**
 * Input definition for a file input.
 * @public
 */
export const file: FormKitTypeDefinition = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: outer(
    wrapper(
      label('$label'),
      inner(
        icon('prefix', 'label'),
        prefix(),
        fileInput(),
        fileList(
          fileItem(
            icon('fileItem'),
            fileName('$file.name'),
            $if(
              '$value.length === 1',
              fileRemove(
                icon('fileRemove'),
                '$ui.remove.value + " " + $file.name'
              )
            )
          )
        ),
        $if('$value.length > 1', fileRemove('$ui.removeAll.value')),
        noFiles(icon('noFiles'), '$ui.noFiles.value'),
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
   * The family of inputs this one belongs too. For example "text" and "email"
   * are both part of the "text" family. This is primary used for styling.
   */
  family: 'text',
  /**
   * An array of extra props to accept for this input.
   */
  props: [],
  /**
   * Additional features that should be added to your input
   */
  features: [
    files,
    defaultIcon('fileItem', 'fileItem'),
    defaultIcon('fileRemove', 'fileRemove'),
    defaultIcon('noFiles', 'noFiles'),
  ],
  /**
   * The key used to memoize the schema.
   */
  schemaMemoKey: '9kqc4852fv8',
}
