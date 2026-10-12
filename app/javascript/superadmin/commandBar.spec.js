import { initializeCommandBar } from './commandBar';

const command = (label, { href, method } = {}) => `
  <div role="option" data-command-item ${method ? `data-command-method="${method}"` : ''}>
    ${href ? `<a href="${href}">${label}</a>` : `<button type="button">${label}</button>`}
  </div>`;

const group = (label, commands) => `
  <div role="group" data-command-group="${label}">${commands.join('')}</div>`;

const BAR = `
  <dialog data-command-bar>
    <input data-command-input>
    <div id="command-bar-list">
      ${group('Go to', [command('Accounts', { href: '/super_admin/accounts' }), command('Users', { href: '/super_admin/users' })])}
      ${group('Account', [command('Reset cache', { href: '/super_admin/accounts/1/reset_cache', method: 'post' })])}
      <div data-command-results="/super_admin/search/accounts"></div>
      <div data-command-results="/super_admin/search/users"></div>
    </div>
  </dialog>`;

const RESULT = group('Accounts', [
  command('Acme Corp', { href: '/super_admin/accounts/7' }),
]);

// jsdom has no dialog methods or scrollIntoView.
HTMLDialogElement.prototype.showModal = function showModal() {
  this.setAttribute('open', '');
};
HTMLDialogElement.prototype.close = function close() {
  this.removeAttribute('open');
  this.dispatchEvent(new Event('close'));
};
Element.prototype.scrollIntoView = vi.fn();

describe('command bar', () => {
  let bar;
  let input;

  const visible = () =>
    [...bar.querySelectorAll('[data-command-item]:not([hidden])')].map(item =>
      item.textContent.trim()
    );
  const selected = () =>
    bar.querySelector('[aria-selected="true"]')?.textContent.trim();
  const type = value => {
    input.value = value;
    input.dispatchEvent(new Event('input'));
  };
  const press = key =>
    bar.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true }));
  const respond = html =>
    Promise.resolve({ ok: true, text: () => Promise.resolve(html) });

  beforeEach(() => {
    vi.useFakeTimers();
    document.body.innerHTML = BAR;
    bar = document.querySelector('[data-command-bar]');
    input = bar.querySelector('[data-command-input]');
    global.fetch = vi.fn(() => respond(''));
    initializeCommandBar();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('filters commands by the typed words and never preselects a command that changes data', () => {
    expect(selected()).toBe('Accounts');

    type('reset');
    expect(visible()).toEqual(['Reset cache']);
    expect(selected()).toBeUndefined();

    press('ArrowDown');
    expect(selected()).toBe('Reset cache');
  });

  it('moves the selection with the arrow keys and runs it with Enter', () => {
    const click = vi.fn();
    bar.querySelector('a[href="/super_admin/users"]').click = click;

    press('ArrowDown');
    expect(selected()).toBe('Users');

    press('Enter');
    expect(click).toHaveBeenCalledOnce();
  });

  it('searches both endpoints once typing pauses and lists what comes back', async () => {
    global.fetch.mockImplementation(url =>
      respond(url.includes('/accounts') ? RESULT : '')
    );

    type('acme');
    expect(bar.hasAttribute('data-searching')).toBe(true);
    expect(global.fetch).not.toHaveBeenCalled();

    await vi.advanceTimersByTimeAsync(200);

    expect(global.fetch.mock.calls.map(([url]) => url)).toEqual([
      '/super_admin/search/accounts?q=acme',
      '/super_admin/search/users?q=acme',
    ]);
    expect(bar.hasAttribute('data-searching')).toBe(false);
    expect(visible()).toEqual(['Acme Corp']);
    expect(selected()).toBe('Acme Corp');
  });

  it('aborts a search the next keystroke makes stale and applies only the latest response', async () => {
    const signals = [];
    global.fetch.mockImplementation((url, { signal }) => {
      signals.push(signal);
      const html = url.includes('/accounts') ? RESULT : '';
      return new Promise((resolve, reject) => {
        signal.addEventListener('abort', () => reject(new Error('aborted')));
        setTimeout(
          () => resolve({ ok: true, text: () => Promise.resolve(html) }),
          500
        );
      });
    });

    type('acme');
    await vi.advanceTimersByTimeAsync(200);
    type('acm');
    await vi.advanceTimersByTimeAsync(200);

    expect(signals.slice(0, 2).every(signal => signal.aborted)).toBe(true);
    expect(bar.hasAttribute('data-searching')).toBe(true);

    await vi.advanceTimersByTimeAsync(500);

    expect(visible()).toEqual(['Acme Corp']);
    expect(bar.querySelectorAll('[aria-selected="true"]').length).toBe(1);
  });

  it('clears the query and results when the dialog closes', async () => {
    global.fetch.mockImplementation(() => respond(RESULT));
    type('acme');
    await vi.advanceTimersByTimeAsync(200);
    expect(visible()).toContain('Acme Corp');

    bar.close();

    expect(input.value).toBe('');
    expect(visible()).toEqual(['Accounts', 'Users', 'Reset cache']);
    expect(selected()).toBe('Accounts');
  });

  it('toggles with the keyboard shortcut', () => {
    document.dispatchEvent(
      new KeyboardEvent('keydown', { key: 'k', metaKey: true })
    );
    expect(bar.open).toBe(true);

    document.dispatchEvent(
      new KeyboardEvent('keydown', { key: 'k', ctrlKey: true })
    );
    expect(bar.open).toBe(false);
  });
});
