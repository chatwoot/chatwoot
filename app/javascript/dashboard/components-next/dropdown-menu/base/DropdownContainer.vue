<script setup>
import { onBeforeUnmount, ref, watch } from 'vue';
import { onKeyStroke } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import DropdownFloating from './DropdownFloating.vue';
import {
  isInnermostOpenMenu,
  markMenuOpen,
  provideDropdownContext,
  useDropdownTeleport,
} from './provider.js';

const emit = defineEmits(['close']);
const isOpen = ref(false);
// useToggle's contract, on a ref this component's watcher tracks: a value sets it, none flips it.
const toggle = (...value) => {
  isOpen.value = value.length ? value[0] : !isOpen.value;
  return isOpen.value;
};

const teleport = useDropdownTeleport();
const containerRef = ref(null);

// A getter, not a computed: consumers swap the trigger element as their state changes — a multi
// select trades its placeholder for a chips button once something is picked.
const getTrigger = () => containerRef.value?.firstElementChild ?? null;

const closeMenu = () => {
  if (isOpen.value) {
    emit('close');
    toggle(false);
  }
};

// Closing the menu removes what had focus inside it (a search field), so Escape hands focus back to
// the trigger, where the keyboard can reopen the menu or move on through the form.
const FOCUSABLE =
  'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';
const focusTrigger = () => {
  const trigger = getTrigger();
  const focusable = trigger?.matches(FOCUSABLE)
    ? trigger
    : trigger?.querySelector(FOCUSABLE);
  focusable?.focus();
};

const menu = {};
watch(isOpen, open => markMenuOpen(menu, open), { flush: 'sync' });
onBeforeUnmount(() => markMenuOpen(menu, false));

// Escape closes the innermost open menu, and only it: a submenu goes first and the menu it sits in
// stays open, and the event is marked handled so a panel or dialog around them stays open too.
// Listening on the document runs this before a panel's window listener.
onKeyStroke(
  'Escape',
  event => {
    if (!isInnermostOpenMenu(menu)) return;
    event.preventDefault();
    closeMenu();
    focusTrigger();
  },
  { target: document }
);

// A teleported menu sits outside the container, so clicks inside it read as clicks outside.
const clickOutsideHandler = [closeMenu, { ignore: ['[data-dropdown-menu]'] }];

provideDropdownContext({
  isOpen,
  toggle,
  closeMenu,
});
</script>

<template>
  <div
    ref="containerRef"
    v-on-click-outside="clickOutsideHandler"
    class="relative space-y-2"
  >
    <slot name="trigger" :is-open :toggle="() => toggle()" />
    <template v-if="isOpen">
      <DropdownFloating v-if="teleport" :trigger="getTrigger">
        <slot />
      </DropdownFloating>
      <div v-else class="absolute">
        <slot />
      </div>
    </template>
  </div>
</template>
