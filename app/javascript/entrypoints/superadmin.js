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

const SPINNER_SVG =
  '<svg class="animate-spin shrink-0" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M21 12a9 9 0 1 1-6.219-8.56" /></svg>';

const initializePendingActions = () => {
  document.addEventListener('submit', event => {
    const button = event.submitter;
    if (!button?.dataset.pendingLabel) return;

    setTimeout(() => {
      if (event.defaultPrevented) return;
      const label = document.createElement('span');
      label.textContent = button.dataset.pendingLabel;
      button.innerHTML = SPINNER_SVG;
      button.append(label);
      button.classList.add('flex', 'items-center', 'gap-2');
      button.disabled = true;
      button.setAttribute('aria-busy', 'true');
    });
  });
};

document.addEventListener('DOMContentLoaded', initializePendingActions);

const closeDropdowns = except => {
  document.querySelectorAll('details[data-dropdown][open]').forEach(menu => {
    if (menu !== except) menu.removeAttribute('open');
  });
};

document.addEventListener('click', event => {
  const trigger = event.target.closest('[data-dialog-open]');
  if (trigger) {
    closeDropdowns();
    document.getElementById(trigger.dataset.dialogOpen)?.showModal();
    return;
  }
  closeDropdowns(event.target.closest('details[data-dropdown]'));
});

document.addEventListener('keydown', event => {
  if (event.key === 'Escape') closeDropdowns();
});

document.addEventListener('DOMContentLoaded', () => {
  const url = new URL(window.location.href);
  if (!url.searchParams.has('suppression')) return;
  url.searchParams.delete('suppression');
  window.history.replaceState(window.history.state, '', url);
});

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('[data-toast-flashes] .flash').forEach(toast => {
    let timer;
    const hide = () => {
      toast.classList.add('opacity-0');
      setTimeout(() => toast.classList.add('invisible'), 300);
    };
    const schedule = () => {
      timer = setTimeout(hide, 8000);
    };
    toast.addEventListener('mouseenter', () => clearTimeout(timer));
    toast.addEventListener('mouseleave', schedule);
    schedule();
  });
});
