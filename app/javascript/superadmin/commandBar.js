const SEARCH_DELAY = 200;
const SELECTED_ID = 'command-bar-selected';

// Devise answers a background request with 401 instead of the login page.
const load = async url => {
  const headers = { 'X-Requested-With': 'XMLHttpRequest' };
  const response = await fetch(url, { headers }).catch(() => null);
  return response?.ok ? response.text() : '';
};

export const initializeCommandBar = () => {
  const bar = document.querySelector('[data-command-bar]');
  const input = bar.querySelector('[data-command-input]');
  const results = bar.querySelector('[data-command-results]');
  let selected;
  let searchTimer;

  const visibleItems = () => [
    ...bar.querySelectorAll('[data-command-item]:not([hidden])'),
  ];

  // A destructive command is selected only with the arrow keys, so a stray Enter cannot run it.
  const isSafe = item => !item.dataset.commandDanger;

  const select = item => {
    selected?.setAttribute('aria-selected', 'false');
    selected?.removeAttribute('id');
    selected = item;
    selected?.setAttribute('aria-selected', 'true');
    selected?.setAttribute('id', SELECTED_ID);
  };

  // Record matches are filtered by the server, so their rows are left alone.
  const filter = () => {
    const terms = input.value.toLowerCase().split(/\s+/).filter(Boolean);
    bar.querySelectorAll('[data-command-group]').forEach(group => {
      const items = [...group.querySelectorAll('[data-command-item]')];
      if (!results.contains(group)) {
        items.forEach(item => {
          const text =
            `${group.dataset.commandGroup} ${item.textContent}`.toLowerCase();
          item.hidden = !terms.every(term => text.includes(term));
        });
      }
      group.hidden = items.every(item => item.hidden);
    });
    select(visibleItems().find(isSafe));
  };

  const search = async () => {
    const query = input.value.trim();
    const html = query
      ? await load(`${bar.dataset.searchUrl}?q=${encodeURIComponent(query)}`)
      : '';
    if (query !== input.value.trim()) return;
    results.innerHTML = html;
    bar.removeAttribute('data-searching');
    if (!visibleItems().includes(selected)) select(visibleItems().find(isSafe));
  };

  const toggleActions = async item => {
    const actions = item.nextElementSibling;
    if (actions?.matches('[data-command-actions]')) {
      actions.remove();
    } else {
      const html = await load(item.dataset.commandRecordUrl);
      const isOpen = item.nextElementSibling?.matches('[data-command-actions]');
      if (!isOpen) item.insertAdjacentHTML('afterend', html);
    }
  };

  input.addEventListener('input', () => {
    filter();
    bar.toggleAttribute('data-searching', Boolean(input.value.trim()));
    clearTimeout(searchTimer);
    searchTimer = setTimeout(search, SEARCH_DELAY);
  });

  bar.addEventListener('keydown', event => {
    // Enter that confirms an IME composition must not run a command.
    if (event.isComposing || event.keyCode === 229) return;

    const items = visibleItems();
    const index = items.indexOf(selected);
    if (event.key === 'ArrowDown') {
      select(items[(index + 1) % items.length]);
    } else if (event.key === 'ArrowUp') {
      select(items.at(Math.max(index, 0) - 1));
    } else if (event.key === 'Enter') {
      selected?.querySelector('a, button').click();
    } else if (event.key === 'Tab' && selected?.dataset.commandRecordUrl) {
      toggleActions(selected);
    } else {
      return;
    }
    event.preventDefault();
    selected?.scrollIntoView({ block: 'nearest' });
  });

  bar.addEventListener('pointermove', event => {
    const item = event.target.closest('[data-command-item]');
    if (item && isSafe(item)) select(item);
  });

  // A click on the backdrop lands on the dialog element itself.
  bar.addEventListener('click', event => {
    if (event.target === bar) bar.close();
    else input.focus();
  });

  bar.addEventListener('close', () => {
    input.value = '';
    input.dispatchEvent(new Event('input'));
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
