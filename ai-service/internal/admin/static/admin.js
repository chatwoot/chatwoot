// fallow-ignore-file unused-file -- loaded by layout.html, embedded with go:embed
// Small enhancements for the ai-service admin pages. Every page works
// without this file; it only adds Copy buttons, "are you sure?" checks and
// Enter-to-send in the test chat.
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

  // <form data-confirm="Question?"> asks before it is sent.
  document.addEventListener('submit', (event) => {
    const form = event.target;
    if (form instanceof HTMLFormElement && form.dataset.confirm && !window.confirm(form.dataset.confirm)) {
      event.preventDefault();
    }
  });
})();
