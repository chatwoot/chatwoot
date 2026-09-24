import '../dashboard/assets/scss/super_admin/index.scss';

const initializeAccountSuspensionForm = () => {
  const form = document.querySelector('[data-account-suspension-form]');
  if (!form) return;

  const status = form.querySelector('[data-account-status-select]');
  const fields = form.querySelector('[data-account-suspension-fields]');
  if (!status || !fields) return;

  const category = fields.querySelector('[data-suspension-category]');
  const reason = fields.querySelector('[data-suspension-reason]');
  const controls = [category, reason];
  const originalStatus = form.dataset.originalStatus;
  const hasHistory = form.dataset.hasSuspensionHistory === 'true';

  const updateFields = () => {
    const isSuspended = status.value === 'suspended';
    const hasEnteredDetails = controls.some(
      control => control.value.trim().length > 0
    );
    const detailsRequired =
      isSuspended &&
      (originalStatus === 'active' || hasHistory || hasEnteredDetails);

    fields.classList.toggle('hidden', !isSuspended);
    controls.forEach(control => {
      control.disabled = !isSuspended;
      control.required = detailsRequired;
    });
  };

  status.addEventListener('change', updateFields);
  controls.forEach(control => control.addEventListener('input', updateFields));
  updateFields();
};

document.addEventListener('DOMContentLoaded', initializeAccountSuspensionForm);

const initializePendingActions = () => {
  document.addEventListener('submit', event => {
    const button = event.submitter;
    if (!button?.dataset.pendingLabel) return;

    setTimeout(() => {
      if (event.defaultPrevented) return;
      button.textContent = button.dataset.pendingLabel;
      button.disabled = true;
      button.setAttribute('aria-busy', 'true');
    });
  });
};

document.addEventListener('DOMContentLoaded', initializePendingActions);

document.addEventListener('click', event => {
  const trigger = event.target.closest('[data-dialog-open]');
  if (!trigger) return;
  document.getElementById(trigger.dataset.dialogOpen)?.showModal();
});
