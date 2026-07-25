function validateForm(formData) {
  // existing validation logic
  let isValid = true;
  for (const field in formData) {
    if (formData[field].required) {
      if (formData[field].type === 'checkbox') {
        if (!formData[field].value) {
          isValid = false;
        }
      } else if (!formData[field].value) {
        isValid = false;
      }
    }
  }
  return isValid;
}