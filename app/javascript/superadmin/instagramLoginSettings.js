export const initializeInstagramLoginSettings = () => {
  const select = document.getElementById('app_config_INSTAGRAM_LOGIN_METHOD');
  if (!select) return;

  const updateFields = () => {
    document.querySelectorAll('[data-instagram-login-method]').forEach(row => {
      const loginMethod = row.dataset.instagramLoginMethod;
      if (!loginMethod) return;

      const visible = loginMethod === select.value;
      row.classList.toggle('hidden', !visible);
      row.classList.toggle('grid', visible);
      row.querySelector('fieldset').disabled = !visible;
    });
  };

  select.addEventListener('change', updateFields);
  updateFields();
};
