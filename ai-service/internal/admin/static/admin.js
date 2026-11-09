// fallow-ignore-file unused-file -- loaded by layout.html, embedded with go:embed
// Small enhancements for the ai-service admin pages. Every page works
// without this file; it only adds Copy buttons, "are you sure?" checks,
// Enter-to-send and a "bot is replying" state in the test chat.
// Rules: never build HTML from strings, no eval, no inline handlers (the CSP allows
// only this file and enforces Trusted Types).
'use strict';
(() => {
  const status = document.createElement('p');
  status.className = 'visually-hidden';
  status.setAttribute('role', 'status');
  document.body.append(status);

  const say = (button, text) => {
    const label = button.dataset.label || button.textContent;
    button.dataset.label = label;
    button.textContent = text;
    status.textContent = text;
    setTimeout(() => { button.textContent = label; }, 1500);
  };

  // <button type="button" data-copy="ID" hidden>Copy</button> copies the
  // value of an input, or the text of any other element, with that id.
  if (navigator.clipboard) {
    for (const button of document.querySelectorAll('button[data-copy]')) {
      const target = document.getElementById(button.dataset.copy);
      if (!target) continue;
      button.hidden = false;
      button.addEventListener('click', async () => {
        const text = target instanceof HTMLInputElement ? target.value : target.textContent;
        try {
          await navigator.clipboard.writeText(text);
          say(button, 'Copied');
        } catch {
          say(button, 'Copy failed');
        }
      });
    }
  }

  // <textarea data-enter-send>: Enter sends the form, Shift+Enter adds a new
  // line. Enter that finishes a word in an input method (Thai, Japanese, ...)
  // is left alone, and an empty box with no file chosen does not send.
  for (const box of document.querySelectorAll('textarea[data-enter-send]')) {
    const hintEl = box.dataset.enterSend && document.getElementById(box.dataset.enterSend);
    if (hintEl) {
      hintEl.hidden = false;
      box.setAttribute('aria-describedby', hintEl.id);
    }
    box.addEventListener('keydown', (event) => {
      if (event.key !== 'Enter' || event.shiftKey || event.altKey || event.ctrlKey || event.metaKey) return;
      if (event.isComposing || event.keyCode === 229) return;
      event.preventDefault();
      const form = box.form;
      if (!form) return;
      const files = form.querySelector('input[type=file]');
      if (box.value.trim() === '' && !(files && files.files && files.files.length)) return;
      form.requestSubmit();
    });
  }

  // <form data-busy="Sending…">: while the server works on the reply, show the
  // customer's message and a typing bubble at once, and block a second send.
  // The page itself is still a plain form post.
  const el = (tag, className, text) => {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text) node.textContent = text;
    return node;
  };
  const showPending = (form) => {
    const section = form.closest('section');
    if (!section) return;
    let chat = section.querySelector('.chat');
    if (!chat) {
      chat = el('div', 'chat');
      chat.setAttribute('role', 'log');
      chat.setAttribute('aria-label', 'Test conversation');
      const empty = section.querySelector('.empty');
      if (empty) empty.replaceWith(chat); else form.before(chat);
    }
    const box = form.querySelector('textarea');
    const text = box ? box.value.trim() : '';
    const files = form.querySelector('input[type=file]');
    const names = files && files.files ? Array.from(files.files, (f) => f.name) : [];
    const mine = el('div', 'bubble user pending');
    mine.append(el('span', 'who', 'You (as customer)'));
    if (text) mine.append(text);
    if (names.length) mine.append((text ? '\n' : '') + 'Attached: ' + names.join(', '));
    const typing = el('div', 'bubble assistant typing pending');
    typing.setAttribute('role', 'status');
    const dots = el('span', 'dots');
    dots.setAttribute('aria-hidden', 'true');
    dots.append(el('span'), el('span'), el('span'));
    typing.append(dots, el('span', '', 'Bot is replying'));
    chat.append(mine, typing);
    typing.scrollIntoView({ block: 'nearest' });
  };
  document.addEventListener('submit', (event) => {
    const form = event.target;
    if (!(form instanceof HTMLFormElement) || !form.dataset.busy || event.defaultPrevented) return;
    if (form.getAttribute('aria-busy') === 'true') {
      event.preventDefault();
      return;
    }
    form.setAttribute('aria-busy', 'true');
    for (const button of form.querySelectorAll('button[type=submit]')) {
      button.dataset.label = button.textContent;
      button.textContent = form.dataset.busy;
      button.disabled = true;
    }
    // Read-only, not disabled: a disabled field would not be sent.
    for (const box of form.querySelectorAll('textarea')) box.readOnly = true;
    showPending(form);
  });
  // Back/forward can restore the page as it was left: undo the busy state.
  window.addEventListener('pageshow', (event) => {
    if (!event.persisted) return;
    for (const form of document.querySelectorAll('form[data-busy][aria-busy]')) {
      form.removeAttribute('aria-busy');
      for (const box of form.querySelectorAll('textarea')) box.readOnly = false;
      for (const button of form.querySelectorAll('button[type=submit]')) {
        button.disabled = false;
        if (button.dataset.label) button.textContent = button.dataset.label;
      }
    }
    for (const node of document.querySelectorAll('.bubble.pending')) node.remove();
  });

  // Phone menu (<details class="menu">): close it when focus moves on to the
  // page below, so nothing focused hides under the open panel, and on Escape.
  for (const menu of document.querySelectorAll('details.menu')) {
    menu.addEventListener('focusout', (event) => {
      // relatedTarget is null for taps that do not move focus (Safari): keep it open then.
      if (menu.open && event.relatedTarget && !menu.contains(event.relatedTarget)) menu.open = false;
    });
    // Focus that lands outside it without leaving it first (a tap on the page) closes it too.
    document.addEventListener('focusin', (event) => {
      if (menu.open && !menu.contains(event.target)) menu.open = false;
    });
    menu.addEventListener('keydown', (event) => {
      if (event.key !== 'Escape' || !menu.open) return;
      menu.open = false;
      menu.querySelector('summary').focus();
    });
  }

  // <form data-confirm="Question?"> asks before it is sent.
  document.addEventListener('submit', (event) => {
    const form = event.target;
    if (form instanceof HTMLFormElement && form.dataset.confirm && !window.confirm(form.dataset.confirm)) {
      event.preventDefault();
    }
  });
})();
