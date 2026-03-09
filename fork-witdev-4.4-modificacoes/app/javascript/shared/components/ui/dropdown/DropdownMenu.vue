<script setup>
import { ref } from 'vue';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

defineProps({
  placement: {
    type: String,
    default: 'top',
  },
});

const dropdownMenuRef = ref(null);

const dropdownMenuButtons = () => {
  return dropdownMenuRef.value.querySelectorAll(
    'ul.dropdown li.dropdown-menu__item .button'
  );
};

const getActiveButtonIndex = menuButtons => {
  const focusedButton = dropdownMenuRef.value.querySelector(
    'ul.dropdown li.dropdown-menu__item .button:focus'
  );
  return Array.from(menuButtons).indexOf(focusedButton);
};

const focusButton = (menuButtons, newIndex) => {
  if (menuButtons.length === 0) return;
  menuButtons[newIndex].focus();
};

const focusPreviousButton = menuButtons => {
  const activeIndex = getActiveButtonIndex(menuButtons);
  const newIndex = activeIndex >= 1 ? activeIndex - 1 : menuButtons.length - 1;
  focusButton(menuButtons, newIndex);
};

const focusNextButton = menuButtons => {
  const activeIndex = getActiveButtonIndex(menuButtons);
  const newIndex = activeIndex === menuButtons.length - 1 ? 0 : activeIndex + 1;
  focusButton(menuButtons, newIndex);
};

const keyboardEvents = {
  ArrowUp: {
    action: () => focusPreviousButton(dropdownMenuButtons()),
    allowOnFocusedInput: true,
  },
  ArrowDown: {
    action: () => focusNextButton(dropdownMenuButtons()),
    allowOnFocusedInput: true,
  },
};

useKeyboardEvents(keyboardEvents);
</script>

<template>
  <ul
    ref="dropdownMenuRef"
    class="dropdown menu vertical"
    :class="[placement && `dropdown--${placement}`]"
  >
    <slot />
  </ul>
</template>
