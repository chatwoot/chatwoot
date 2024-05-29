import { debounce } from '@chatwoot/utils';

const RESIZE_OBSERVER_DEBOUNCE_TIME = 100;

function createResizeObserver(el, binding) {
  const { value } = binding;
  const observer = new ResizeObserver(
    debounce(entries => {
      const entry = entries[0];
      if (entry && value && typeof value === 'function') {
        value(entry);
      }
    }, RESIZE_OBSERVER_DEBOUNCE_TIME)
  );

  el.cwResizeObserver = observer;
  observer.observe(el);
}

function destroyResizeObserver(el) {
  if (el.cwResizeObserver) {
    el.cwResizeObserver.unobserve(el);
    el.cwResizeObserver.disconnect();
    delete el.cwResizeObserver;
  }
}

export default {
  bind(el, binding) {
    createResizeObserver(el, binding);
  },
  update(el, binding) {
    if (binding.oldValue !== binding.value) {
      destroyResizeObserver(el);
      createResizeObserver(el, binding);
    }
  },
  unbind(el) {
    destroyResizeObserver(el);
  },
};
