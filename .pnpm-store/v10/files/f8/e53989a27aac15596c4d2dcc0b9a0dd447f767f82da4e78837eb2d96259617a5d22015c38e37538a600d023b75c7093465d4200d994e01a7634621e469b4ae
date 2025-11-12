/* eslint-disable class-methods-use-this */
// ::- The type of field that `FieldPrompt` expects to be passed to it.
export class Field {
  // :: (Object)
  // Create a field with the given options. Options support by all
  // field types are:
  //
  // **`value`**`: ?any`
  //   : The starting value for the field.
  //
  // **`label`**`: string`
  //   : The label for the field.
  //
  // **`required`**`: ?bool`
  //   : Whether the field is required.
  //
  // **`validate`**`: ?(any) → ?string`
  //   : A function to validate the given value. Should return an
  //     error message if it is not valid.
  constructor(options) {
    this.options = options;
  }

  // render:: (state: EditorState, props: Object) → dom.Node
  // Render the field to the DOM. Should be implemented by all subclasses.

  // :: (dom.Node) → any
  // Read the field's value from its DOM node.
  read(dom) {
    return dom.value;
  }

  // :: (any) → ?string
  // A field-type-specific validation function.
  validateType() {}

  validate(value) {
    if (!value && this.options.required) return 'Required field';
    return (
      this.validateType(value) ||
      (this.options.validate && this.options.validate(value))
    );
  }

  clean(value) {
    return this.options.clean ? this.options.clean(value) : value;
  }
}
