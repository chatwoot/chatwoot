// This module is deferred, so the document is already parsed when it runs.

const swapIcons = button =>
  button.querySelectorAll('span').forEach(icon => {
    icon.classList.toggle('hidden');
  });

// The <head> script applies the stored theme before first paint; this keeps
// the switch and the page in sync afterwards.
const THEME_STORAGE_KEY = 'super-admin-theme';
const systemDarkQuery = window.matchMedia('(prefers-color-scheme: dark)');

const applyTheme = () => {
  const theme = localStorage.getItem(THEME_STORAGE_KEY) || 'system';
  const isDark =
    theme === 'dark' || (theme === 'system' && systemDarkQuery.matches);
  document.documentElement.classList.toggle('dark', isDark);
  document.querySelectorAll('[data-theme-value]').forEach(button => {
    button.setAttribute(
      'aria-pressed',
      String(button.dataset.themeValue === theme)
    );
  });
};

systemDarkQuery.addEventListener('change', applyTheme);
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

  // A click on a sheet's backdrop lands on the dialog element itself.
  if (target.matches('dialog[data-sheet]')) target.close();

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

// Handled while the event travels down, so a click on a secret's buttons
// inside a table row does not also open the row.
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
      navigator.clipboard.writeText(secret).then(() => {
        swapIcons(button);
        setTimeout(() => swapIcons(button), 1500);
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
const keepSearchFilter = form => {
  const input = form.elements.search;
  input.value = `${form.dataset.searchFilter}: ${input.value}`.trim();
};

// Posts the form in the background and copies the link it returns. The
// clipboard is given a promise so Safari still treats it as part of the click.
const copyLinkFromForm = form => {
  const button = form.querySelector('button');
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
  if (form.dataset.searchFilter) keepSearchFilter(form);
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

const initializeTabs = () => {
  const tabs = [...document.querySelectorAll('[data-tab]')];

  tabs.forEach(tab =>
    tab.addEventListener('click', () => {
      const name = tab.dataset.tab;
      tabs.forEach(item =>
        item.setAttribute('aria-selected', String(item === tab))
      );
      document.querySelectorAll('[data-tab-panel]').forEach(panel => {
        panel.hidden = panel.dataset.tabPanel !== name;
      });
      // The page reads this cookie to render with the same tab open, so a reload,
      // a page change or a form submit does not start on the first tab.
      const value = encodeURIComponent(`${window.location.pathname}#${name}`);
      document.cookie = `super_admin_tab=${value}; path=/super_admin; SameSite=Lax`;
    })
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
    scope.addEventListener('change', updateCount);
    updateCount();
  });
};

const initializeToasts = () => {
  document.querySelectorAll('[data-toast-flashes] > *').forEach(toast => {
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
  window.addEventListener('pageshow', () =>
    bar.classList.remove('animate-page-progress')
  );
};

initializeAccountSuspensionForm();
initializeBannerForm();
initializeTabs();
initializeFilters();
initializeToasts();
clearSuppressionParam();
initializePageProgress();
