const SEARCH_DELAY = 200;
const SELECTED_ID = 'command-bar-selected';

// Devise answers a background request with 401 instead of the login page.
const load = async (url, signal) => {
  const headers = { 'X-Requested-With': 'XMLHttpRequest' };
  try {
    const response = await fetch(url, { headers, signal });
    return response.ok ? await response.text() : '';
  } catch {
    return '';
  }
};

export const initializeCommandBar = () => {
  const bar = document.querySelector('[data-command-bar]');
  const input = bar.querySelector('[data-command-input]');
  const results = [...bar.querySelectorAll('[data-command-results]')];
  let selected;
  let searchTimer;
  let controller;

  const visibleItems = () => [
    ...bar.querySelectorAll('[data-command-item]:not([hidden])'),
  ];

  // A command that changes data is selected only with the arrow keys, so a stray Enter cannot run it.
  const isSafe = item => !item.dataset.commandMethod;

  const select = item => {
    selected?.setAttribute('aria-selected', 'false');
    selected?.removeAttribute('id');
    selected = item;
    selected?.setAttribute('aria-selected', 'true');
    selected?.setAttribute('id', SELECTED_ID);
  };

  const filter = () => {
    const terms = input.value.toLowerCase().split(/\s+/).filter(Boolean);
    bar.querySelectorAll('[data-command-group]').forEach(group => {
      const items = [...group.querySelectorAll('[data-command-item]')];
      items.forEach(item => {
        const text =
          `${group.dataset.commandGroup} ${item.textContent}`.toLowerCase();
        item.hidden = !terms.every(term => text.includes(term));
      });
      group.hidden = items.every(item => item.hidden);
    });
    select(visibleItems().find(isSafe));
  };

  const search = async query => {
    controller = new AbortController();
    const { signal } = controller;
    const params = new URLSearchParams({ q: query });
    const pages = await Promise.all(
      results.map(list =>
        load(`${list.dataset.commandResults}?${params}`, signal)
      )
    );
    if (signal.aborted) return;
    results.forEach((list, index) => {
      list.innerHTML = pages[index];
    });
    bar.removeAttribute('data-searching');
    if (!selected) select(visibleItems().find(isSafe));
  };

  const update = () => {
    const query = input.value.trim();
    controller?.abort();
    results.forEach(list => list.replaceChildren());
    bar.toggleAttribute('data-searching', Boolean(query));
    filter();
    clearTimeout(searchTimer);
    if (query) searchTimer = setTimeout(search, SEARCH_DELAY, query);
  };

  input.addEventListener('input', update);

  bar.addEventListener('keydown', event => {
    // Enter that confirms an IME composition must not run a command.
    if (event.isComposing || event.keyCode === 229) return;

    const items = visibleItems();
    const index = items.indexOf(selected);
    if (event.key === 'ArrowDown') {
      select(items[(index + 1) % items.length]);
    } else if (event.key === 'ArrowUp') {
      select(items.at(Math.max(index, 0) - 1));
    } else if (event.key === 'Enter' && !event.repeat) {
      selected?.querySelector('a, button').click();
    } else if (event.key !== 'Tab') {
      return;
    }
    // Tab is swallowed too: it would take the focus out of the input.
    event.preventDefault();
    selected?.scrollIntoView({ block: 'nearest' });
  });

  bar.addEventListener('pointermove', event => {
    const item = event.target.closest('[data-command-item]');
    if (item && isSafe(item)) select(item);
  });

  // A click on the backdrop lands on the dialog element itself.
  bar.addEventListener('click', event => {
    const opensDialog = event.target.closest('[data-dialog-open]');
    if (event.target === bar || opensDialog) bar.close();
    else input.focus();
  });

  bar.addEventListener('close', () => {
    input.value = '';
    update();
  });

  document.addEventListener('keydown', event => {
    if (event.key?.toLowerCase() !== 'k') return;
    if (!event.metaKey && !event.ctrlKey) return;
    event.preventDefault();
    if (bar.open) bar.close();
    else bar.showModal();
  });

  // A page restored from the back/forward cache comes back as it was left.
  window.addEventListener('pageshow', () => bar.close());

  filter();
};
