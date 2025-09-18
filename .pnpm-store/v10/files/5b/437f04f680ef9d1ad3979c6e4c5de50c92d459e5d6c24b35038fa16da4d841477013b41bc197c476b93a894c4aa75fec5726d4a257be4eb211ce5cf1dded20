import Field from './Field';

// ::- A field class for dropdown fields based on a plain `<select>`
// tag. Expects an option `options`, which should be an array of
// `{value: string, label: string}` objects, or a function taking a
// `ProseMirror` instance and returning such an array.
export class SelectField extends Field {
  render() {
    let select = document.createElement('select');
    this.options.options.forEach(o => {
      let opt = select.appendChild(document.createElement('option'));
      opt.value = o.value;
      opt.selected = o.value === this.options.value;
      opt.label = o.label;
    });
    return select;
  }
}
