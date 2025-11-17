const PRIMARY_COLOR_SELECTOR = '[data-primary-color-config]';
const HEX_PATTERN = /^#[0-9A-F]{6}$/;
const FALLBACK_COLOR = '#2781F6';
const VALIDATION_MESSAGE = 'Please enter a hex color in #RRGGBB format.';

const getNormalizedHex = value => (value || '').toString().trim().toUpperCase();

const applyCssPreview = (color, preview) => {
  document.documentElement.style.setProperty('--cw-admin-primary-preview', color);
  if (preview) {
    preview.style.setProperty('background-color', color);
  }
};

const mountPrimaryColorControl = () => {
  const container = document.querySelector(PRIMARY_COLOR_SELECTOR);
  if (!container) {
    return;
  }

  const textInput = container.querySelector('[data-primary-color-input]');
  const colorInput = container.querySelector('[data-primary-color-picker]');
  const preview = container.querySelector('[data-primary-color-preview]');
  const errorMessage = container.querySelector('[data-primary-color-error]');
  const fallback = getNormalizedHex(container.dataset.defaultColor || FALLBACK_COLOR);

  const setValidity = normalizedValue => {
    if (!textInput) {
      return;
    }

    if (HEX_PATTERN.test(normalizedValue)) {
      textInput.setCustomValidity('');
      errorMessage?.classList.add('hidden');
      return;
    }

    textInput.setCustomValidity(VALIDATION_MESSAGE);
    if (normalizedValue === '') {
      errorMessage?.classList.add('hidden');
    } else {
      errorMessage?.classList.remove('hidden');
    }
  };

  const updateFromValue = value => {
    const normalized = getNormalizedHex(value);
    const isValid = HEX_PATTERN.test(normalized);
    const targetColor = isValid ? normalized : fallback;

    if (colorInput) {
      colorInput.value = targetColor;
    }

    applyCssPreview(targetColor, preview);
    setValidity(normalized);

    return normalized;
  };

  if (container.dataset.initialized === 'true') {
    updateFromValue(textInput?.value || fallback);
    return;
  }

  container.dataset.initialized = 'true';

  textInput?.addEventListener('input', event => {
    const normalized = getNormalizedHex(event.target.value);
    const isValid = HEX_PATTERN.test(normalized);
    const targetColor = isValid ? normalized : fallback;

    applyCssPreview(targetColor, preview);
    if (colorInput && isValid) {
      colorInput.value = normalized;
    }
    setValidity(normalized);
  });

  textInput?.addEventListener('blur', () => {
    const normalized = updateFromValue(textInput.value);
    textInput.value = normalized;
  });

  textInput?.addEventListener('change', () => {
    const normalized = updateFromValue(textInput.value);
    textInput.value = normalized;
  });

  colorInput?.addEventListener('input', event => {
    const normalized = updateFromValue(event.target.value);
    if (textInput) {
      textInput.value = normalized;
    }
  });

  updateFromValue(textInput?.value || fallback);
};

const registerPrimaryColorControl = () => {
  mountPrimaryColorControl();
};

['DOMContentLoaded', 'turbolinks:load', 'turbo:load', 'turbo:render'].forEach(eventName => {
  document.addEventListener(eventName, registerPrimaryColorControl);
});

document.addEventListener('turbo:before-cache', () => {
  const container = document.querySelector(PRIMARY_COLOR_SELECTOR);
  if (!container) {
    return;
  }

  const textInput = container.querySelector('[data-primary-color-input]');
  const preview = container.querySelector('[data-primary-color-preview]');

  applyCssPreview(getNormalizedHex(textInput?.value || FALLBACK_COLOR), preview);
});
