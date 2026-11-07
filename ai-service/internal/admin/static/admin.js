// Small enhancements for the ai-service admin pages. Every page works
// without this file; it only adds Copy buttons and "are you sure?" checks.
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

  // <form data-confirm="Question?"> asks before it is sent.
  document.addEventListener('submit', (event) => {
    const form = event.target;
    if (form instanceof HTMLFormElement && form.dataset.confirm && !window.confirm(form.dataset.confirm)) {
      event.preventDefault();
    }
  });
})();
