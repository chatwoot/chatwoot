import '../storefront/application.scss';

/**
 * Storefront JavaScript — vanilla JS, no framework dependencies.
 * Handles: add-to-cart, quantity stepper, cart badge updates, floating cart.
 */

const csrfToken = () =>
  document.querySelector('meta[name="csrf-token"]')?.content;

// ─── Floating Cart Bar ──────────────────────────────────────
function updateFloatingCart(count) {
  const bar = document.getElementById('floating-cart');
  const countEl = document.getElementById('floating-cart-count');
  if (!bar) return;

  if (count > 0) {
    bar.classList.remove(
      'translate-y-full',
      'opacity-0',
      'pointer-events-none'
    );
    bar.classList.add('translate-y-0', 'opacity-100');
    if (countEl) countEl.textContent = count;
  } else {
    bar.classList.add('translate-y-full', 'opacity-0', 'pointer-events-none');
    bar.classList.remove('translate-y-0', 'opacity-100');
  }
}

// ─── Cart Badge ──────────────────────────────────────────────
function updateCartBadge(count) {
  const badge = document.getElementById('cart-badge');
  const cartIcon = document.getElementById('cart-icon');

  if (count > 0) {
    if (badge) {
      badge.textContent = count;
    } else if (cartIcon) {
      const span = document.createElement('span');
      span.id = 'cart-badge';
      span.className =
        'absolute -top-1.5 -right-1.5 bg-woot-500 text-white text-xs font-bold rounded-full h-5 min-w-[1.25rem] flex items-center justify-center px-1';
      span.textContent = count;
      cartIcon.appendChild(span);
    }
  } else if (badge) {
    badge.remove();
  }

  updateFloatingCart(count);
}

// ─── Card Stepper Toggle ────────────────────────────────────
function showStepper(control, qty) {
  const stepper = control.querySelector('[data-stepper]');
  const singleAdd = control.querySelector('[data-single-add]');
  const qtyDisplay = control.querySelector('[data-qty-display]');

  if (stepper) stepper.classList.remove('hidden');
  if (singleAdd) singleAdd.classList.add('hidden');
  if (qtyDisplay) qtyDisplay.textContent = qty;
}

function hideStepper(control) {
  const stepper = control.querySelector('[data-stepper]');
  const singleAdd = control.querySelector('[data-single-add]');

  if (stepper) stepper.classList.add('hidden');
  if (singleAdd) singleAdd.classList.remove('hidden');
}

// ─── Add to Cart (product cards & detail page) ──────────────
function initAddToCart() {
  document.querySelectorAll('[data-add-to-cart]').forEach(form => {
    form.addEventListener('submit', event => {
      event.preventDefault();
      const formData = new FormData(form);

      fetch(form.action, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'X-CSRF-Token': csrfToken(),
        },
        body: formData,
      })
        .then(r => r.json())
        .then(data => {
          updateCartBadge(data.cart_count);

          const control = form.closest('[data-cart-control]');
          if (control) {
            // Card button — update stepper
            const qtyDisplay = control.querySelector('[data-qty-display]');
            const currentQty = parseInt(qtyDisplay?.textContent, 10) || 0;
            showStepper(control, currentQty + 1);
            return;
          }

          // Detail page text button — "Added!" feedback
          const btn = form.querySelector('button[type="submit"]');
          if (btn && btn.textContent.trim().length > 0) {
            const original = btn.textContent;
            btn.textContent = 'Added!';
            btn.classList.add('bg-green-500');
            btn.classList.remove('bg-woot-500');
            setTimeout(() => {
              btn.textContent = original;
              btn.classList.remove('bg-green-500');
              btn.classList.add('bg-woot-500');
            }, 1200);
          }
        })
        .catch(() => form.submit());
    });
  });
}

// ─── Decrement / Remove from Cart (product cards) ───────────
function initDecrement() {
  document.querySelectorAll('[data-decrement]').forEach(btn => {
    btn.addEventListener('click', () => {
      const control = btn.closest('[data-cart-control]');
      if (!control) return;

      const qtyDisplay = control.querySelector('[data-qty-display]');
      const currentQty = parseInt(qtyDisplay?.textContent, 10) || 0;
      if (currentQty <= 0) return;

      const isRemove = currentQty === 1;
      const url = isRemove
        ? control.dataset.removeUrl
        : control.dataset.updateUrl;
      const method = isRemove ? 'DELETE' : 'PATCH';
      const headers = {
        Accept: 'application/json',
        'X-CSRF-Token': csrfToken(),
      };

      const fetchOpts = { method, headers };
      if (!isRemove) {
        headers['Content-Type'] = 'application/json';
        fetchOpts.body = JSON.stringify({ quantity: currentQty - 1 });
      }

      // Optimistic UI update
      if (isRemove) {
        hideStepper(control);
      } else {
        qtyDisplay.textContent = currentQty - 1;
      }

      fetch(url, fetchOpts)
        .then(r => r.json())
        .then(data => updateCartBadge(data.cart_count))
        .catch(() => window.location.reload());
    });
  });
}

// ─── Quantity Stepper (product detail page) ──────────────────
function initQuantityStepper() {
  document.querySelectorAll('[data-qty-input]').forEach(input => {
    const wrapper = input.closest('[data-qty-stepper]');
    if (!wrapper) return;

    const decBtn = wrapper.querySelector('[data-qty-dec]');
    const incBtn = wrapper.querySelector('[data-qty-inc]');

    if (decBtn) {
      decBtn.addEventListener('click', () => {
        const val = parseInt(input.value, 10) || 1;
        if (val > 1) input.value = val - 1;
      });
    }
    if (incBtn) {
      incBtn.addEventListener('click', () => {
        const val = parseInt(input.value, 10) || 1;
        if (val < 99) input.value = val + 1;
      });
    }
  });
}

// ─── Cart Page Quantity Controls ─────────────────────────────
function initCartQuantity() {
  document.querySelectorAll('[data-cart-qty]').forEach(wrapper => {
    const url = wrapper.dataset.cartQtyUrl;
    const display = wrapper.querySelector('[data-cart-qty-display]');
    const decBtn = wrapper.querySelector('[data-cart-qty-dec]');
    const incBtn = wrapper.querySelector('[data-cart-qty-inc]');

    if (!display || !url) return;

    const update = quantity => {
      display.textContent = quantity;
      fetch(url, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          'X-CSRF-Token': csrfToken(),
        },
        body: JSON.stringify({ quantity }),
      })
        .then(r => r.json())
        .then(() => window.location.reload())
        .catch(() => window.location.reload());
    };

    if (decBtn) {
      decBtn.addEventListener('click', () => {
        const val = parseInt(display.textContent, 10) || 1;
        if (val > 1) update(val - 1);
      });
    }
    if (incBtn) {
      incBtn.addEventListener('click', () => {
        const val = parseInt(display.textContent, 10) || 1;
        if (val < 99) update(val + 1);
      });
    }
  });
}

// ─── Init ────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  initAddToCart();
  initDecrement();
  initQuantityStepper();
  initCartQuantity();
});
