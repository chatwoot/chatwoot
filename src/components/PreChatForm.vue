methods: {
  submitForm() {
    const checkboxAttributes = this.getCheckboxAttributes();
    const isValid = validateForm(this.formState, checkboxAttributes);
    if (isValid) {
      // proceed with form submission
    }
  },
  getCheckboxAttributes() {
    return [
      { name: 'terms', required: true, value: this.formState.terms },
      // add other checkboxes as needed
    ];
  }
}