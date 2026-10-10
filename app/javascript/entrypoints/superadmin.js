import { initializeCommandBar } from '../superadmin/commandBar';

// This module is deferred, so the document is already parsed when it runs.

const swapIcons = button =>
  button.querySelectorAll('span').forEach(icon => {
    icon.classList.toggle('hidden');
  });

// The <head> script applies the stored theme and follows the system theme; this
// applies a choice made with the switch and keeps the switch in sync.
const THEME_STORAGE_KEY = 'super-admin-theme';
const systemDarkQuery = window.matchMedia('(prefers-color-scheme: dark)');

const applyTheme = () => {
  const theme = localStorage.getItem(THEME_STORAGE_KEY) || 'system';
  const isDark =
    theme === 'dark' || (theme !== 'light' && systemDarkQuery.matches);
  document.documentElement.classList.toggle('dark', isDark);
  document.querySelectorAll('[data-theme-value]').forEach(button => {
    button.setAttribute(
      'aria-pressed',
      String(button.dataset.themeValue === theme)
    );
  });
};

applyTheme();

const closeDropdowns = except => {
  document.querySelectorAll('details[data-dropdown][open]').forEach(menu => {
    if (menu !== except) menu.removeAttribute('open');
  });
};

document.addEventListener('click', event => {
  const { target } = event;

  const themeButton = target.closest('[data-theme-value]');
  if (themeButton) {
    localStorage.setItem(THEME_STORAGE_KEY, themeButton.dataset.themeValue);
    applyTheme();
  }

  const dialogOpener = target.closest('[data-dialog-open]');
  if (dialogOpener) {
    closeDropdowns();
    document.getElementById(dialogOpener.dataset.dialogOpen)?.showModal();
    return;
  }

  // A click on a dialog's backdrop lands on the dialog element itself.
  if (target.matches('dialog[data-backdrop-close]')) target.close();

  if (target.closest('[data-support-chat]')) window.$chatwoot?.toggle('open');

  const revealButton = target.closest('[data-reveal]');
  if (revealButton) {
    const input = document.getElementById(revealButton.dataset.reveal);
    input.type = input.type === 'password' ? 'text' : 'password';
    swapIcons(revealButton);
  }

  closeDropdowns(target.closest('details[data-dropdown]'));
});

document.addEventListener('keydown', event => {
  if (event.key === 'Escape') closeDropdowns();
});

// Administrate's table.js opens a row on click, Enter and Space unless the
// target is a link, so a button inside a row has to stop the event first.
document.addEventListener(
  'keydown',
  event => {
    if (event.key !== 'Enter' && event.key !== ' ') return;
    if (event.target.matches('.js-table-row button')) event.stopPropagation();
  },
  true
);

document.addEventListener(
  'click',
  event => {
    const button = event.target.closest(
      '[data-secret-toggle], [data-secret-copy]'
    );
    if (!button) return;
    event.preventDefault();
    event.stopPropagation();

    const { secret } = button.closest('[data-secret]').dataset;
    if (button.matches('[data-secret-copy]')) {
      if (button.disabled) return;
      navigator.clipboard.writeText(secret).then(() => {
        button.disabled = true;
        swapIcons(button);
        setTimeout(() => {
          swapIcons(button);
          button.disabled = false;
        }, 1500);
      });
      return;
    }

    const text = button.parentElement.querySelector('[data-secret-text]');
    const isRevealed = text.textContent === secret;
    text.textContent = isRevealed ? '•'.repeat(secret.length || 10) : secret;
    swapIcons(button);
  },
  true
);

const SPINNER_SVG =
  '<svg class="animate-spin shrink-0" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M21 12a9 9 0 1 1-6.219-8.56" /></svg>';

const showPendingLabel = event => {
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
};

// The list filter travels inside the search term as `<filter>: <text>`.
document.addEventListener('formdata', event => {
  const filter = event.target.dataset.searchFilter;
  if (!filter) return;
  const text = event.formData.get('search') || '';
  event.formData.set('search', `${filter}: ${text}`.trim());
});

// Posts the form in the background and copies the link it returns. The
// clipboard is given a promise so Safari still treats it as part of the click.
const copyLinkFromForm = form => {
  const button = form.querySelector('button');
  if (button.disabled) return;
  button.disabled = true;
  const label = button.textContent;
  const link = fetch(form.action, {
    method: 'POST',
    body: new FormData(form),
    headers: { Accept: 'application/json' },
  })
    .then(response => {
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      return response.json();
    })
    .then(data => data.url);
  const writeText = () => link.then(url => navigator.clipboard.writeText(url));
  let copy;
  try {
    copy = window.ClipboardItem
      ? navigator.clipboard.write([
          new ClipboardItem({
            'text/plain': link.then(
              url => new Blob([url], { type: 'text/plain' })
            ),
          }),
        ])
      : writeText();
  } catch {
    copy = writeText();
  }
  const showResult = text => {
    button.textContent = text;
    setTimeout(() => {
      button.textContent = label;
      button.disabled = false;
    }, 2000);
  };
  copy
    .then(() => showResult(form.dataset.copiedLabel))
    .catch(() => showResult(form.dataset.failedLabel));
};

document.addEventListener('submit', event => {
  const form = event.target;
  if (form.matches('[data-copy-link]')) {
    event.preventDefault();
    copyLinkFromForm(form);
    return;
  }
  if (form.target === '_blank') form.closest('dialog')?.close();
  showPendingLabel(event);
});

document.addEventListener('change', event => {
  if (!event.target.matches('[data-check-toggle]')) return;
  event.target
    .closest('table')
    .querySelectorAll('tbody [type="checkbox"]')
    .forEach(checkbox => {
      checkbox.checked = event.target.checked;
    });
});

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

const initializeCaptainModelControls = () => {
  document.querySelectorAll('[data-captain-model-controls]').forEach(card => {
    const effort = card.querySelector('[data-captain-effort]');
    if (!effort) return;

    const model = card.querySelector('[data-captain-model]');
    const options = JSON.parse(card.dataset.effortOptions);
    model.addEventListener('change', () => {
      const previous = effort.value;
      const choices = options[model.value];
      effort.replaceChildren(
        effort.options[0],
        ...choices.map(([label, value]) => new Option(label, value))
      );
      effort.value = choices.some(([, value]) => value === previous)
        ? previous
        : '';
    });
  });
};

// Platform banners: a title and a video only apply to feature announcements.
const initializeBannerForm = () => {
  const type = document.getElementById('platform_banner_banner_type');
  if (!type) return;

  const inputs = ['platform_banner_title', 'platform_banner_video_url'].map(
    id => document.getElementById(id)
  );
  const updateFields = () => {
    const isAnnouncement = type.value === 'feature_announcement';
    inputs.forEach(input => {
      input.disabled = !isAnnouncement;
      input.closest('[data-field]').classList.toggle('hidden', !isAnnouncement);
    });
  };

  // Selectize reports changes through jQuery, which native listeners never hear.
  window.jQuery(type).on('change', updateFields);
  updateFields();
};

const showTab = name => {
  document.querySelectorAll('[data-tab]').forEach(tab => {
    tab.setAttribute('aria-selected', String(tab.dataset.tab === name));
  });
  document.querySelectorAll('[data-tab-panel]').forEach(panel => {
    panel.hidden = panel.dataset.tabPanel !== name;
  });
  // The page reads this cookie to render with the same tab open, so a reload,
  // a page change or a form submit does not start on the first tab.
  const value = encodeURIComponent(`${window.location.pathname}#${name}`);
  document.cookie = `super_admin_tab=${value}; path=/super_admin; SameSite=Lax`;
};

const initializeTabs = () => {
  document
    .querySelectorAll('[data-tab]')
    .forEach(tab =>
      tab.addEventListener('click', () => showTab(tab.dataset.tab))
    );

  // The browser cannot focus an invalid control on a hidden tab, so it would drop
  // the submit without a word. Bring that tab forward before it tries.
  document.addEventListener(
    'invalid',
    event => {
      const control = event.target;
      const firstInvalid = control.form?.querySelector(
        'input:invalid, select:invalid, textarea:invalid'
      );
      if (control !== firstInvalid) return;
      const panel = control.closest('[data-tab-panel]');
      if (panel?.hidden) showTab(panel.dataset.tabPanel);
    },
    true
  );
};

const initializeFilters = () => {
  document.querySelectorAll('[data-filter-scope]').forEach(scope => {
    const items = [...scope.querySelectorAll('[data-filter-item]')];
    const checkboxOf = item => item.querySelector('[type="checkbox"]');
    const checkboxes = items.map(checkboxOf).filter(Boolean);
    const isOn = item =>
      checkboxOf(item)?.checked ?? item.dataset.state === 'on';
    const input = scope.querySelector('[data-filter-input]');
    const stateButtons = [...scope.querySelectorAll('[data-filter-state]')];
    const counter = scope.querySelector('[data-check-count]');
    let state = 'all';

    const updateCount = () => {
      if (!counter) return;
      const checked = checkboxes.filter(checkbox => checkbox.checked).length;
      counter.textContent = counter.dataset.checkCount
        .replace('%{selected}', checked)
        .replace('%{total}', checkboxes.length);
    };

    const applyFilter = () => {
      const query = input ? input.value.trim().toLowerCase() : '';
      items.forEach(item => {
        const matchesText = item.textContent.toLowerCase().includes(query);
        const matchesState = state === 'all' || isOn(item) === (state === 'on');
        item.classList.toggle('hidden', !matchesText || !matchesState);
      });
      scope.querySelectorAll('[data-filter-group]').forEach(group => {
        const hasVisibleItem = group.querySelector(
          '[data-filter-item]:not(.hidden)'
        );
        group.classList.toggle('hidden', !hasVisibleItem);
      });
      scope.querySelector('[data-filter-empty]')?.classList.toggle(
        'hidden',
        items.some(item => !item.classList.contains('hidden'))
      );
    };

    const setVisibleCheckboxes = checked => {
      items
        .filter(item => !item.classList.contains('hidden'))
        .map(checkboxOf)
        .filter(checkbox => checkbox && !checkbox.disabled)
        .forEach(checkbox => {
          checkbox.checked = checked;
        });
      updateCount();
      applyFilter();
    };

    input?.addEventListener('input', applyFilter);
    input?.addEventListener('keydown', event => {
      if (event.key === 'Enter') event.preventDefault();
    });
    stateButtons.forEach(button =>
      button.addEventListener('click', () => {
        state = button.dataset.filterState;
        stateButtons.forEach(other =>
          other.setAttribute('aria-pressed', String(other === button))
        );
        applyFilter();
      })
    );
    scope
      .querySelector('[data-check-all]')
      ?.addEventListener('click', () => setVisibleCheckboxes(true));
    scope
      .querySelector('[data-check-none]')
      ?.addEventListener('click', () => setVisibleCheckboxes(false));
    // A state filter keeps showing what it filtered on, so re-run it when a box changes.
    scope.addEventListener('change', () => {
      updateCount();
      applyFilter();
    });
    updateCount();
  });
};

const initializeToasts = () => {
  document.querySelectorAll('[data-toast]').forEach(toast => {
    let timer;
    const hide = () => {
      clearTimeout(timer);
      toast.classList.add('opacity-0');
      setTimeout(() => toast.remove(), 300);
    };
    toast.querySelector('[data-toast-close]').addEventListener('click', hide);
    if ('toastSticky' in toast.dataset) return;

    const schedule = () => {
      timer = setTimeout(hide, 8000);
    };
    ['mouseenter', 'focusin'].forEach(type =>
      toast.addEventListener(type, () => clearTimeout(timer))
    );
    ['mouseleave', 'focusout'].forEach(type =>
      toast.addEventListener(type, schedule)
    );
    schedule();
  });
};

// The email suppression result arrives as a query param; drop it so a reload
// does not show a stale result.
const clearSuppressionParam = () => {
  const url = new URL(window.location.href);
  if (!url.searchParams.has('suppression')) return;
  url.searchParams.delete('suppression');
  window.history.replaceState(window.history.state, '', url);
};

const initializePageProgress = () => {
  const bar = document.querySelector('[data-page-progress]');
  if (!bar || !window.navigation) return;

  window.navigation.addEventListener('navigate', event => {
    if (event.destination.sameDocument || event.downloadRequest !== null)
      return;
    bar.classList.add('animate-page-progress');
  });
  const reset = () => bar.classList.remove('animate-page-progress');
  window.addEventListener('pageshow', reset);
  window.navigation.addEventListener('navigateerror', reset);
};

initializeAccountSuspensionForm();
initializeCaptainModelControls();
initializeBannerForm();
initializeTabs();
initializeFilters();
initializeToasts();
clearSuppressionParam();
initializePageProgress();
initializeCommandBar();
