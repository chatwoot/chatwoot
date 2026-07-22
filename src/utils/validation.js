function validateForm(formState, checkboxAttributes) {
  // existing validation logic
  let isValid = true;
  // ... other validation checks
  checkboxAttributes.forEach(attribute => {
    if (attribute.required && !attribute.value) {
      isValid = false;
    }
  });
  return isValid;
}