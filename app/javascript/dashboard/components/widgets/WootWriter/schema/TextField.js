import { Field } from './Field';

// ::- A field class for single-line text fields.
export class TextField extends Field {
  render() {
    let input = document.createElement('input');
    input.type = 'text';
    input.placeholder = this.options.label;
    input.value = this.options.value || '';
    input.autocomplete = 'off';
    return input;
  }
}
