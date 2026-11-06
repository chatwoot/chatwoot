<script setup>
import { computed, useAttrs } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useDropdownContext } from './provider.js';

const props = defineProps({
  label: { type: String, default: '' },
  icon: { type: [String, Object, Function], default: '' },
  link: { type: [String, Object], default: '' },
  nativeLink: { type: Boolean, default: false },
  click: { type: Function, default: null },
  preserveOpen: { type: Boolean, default: false },
});

defineOptions({
  inheritAttrs: false,
});

const { closeMenu } = useDropdownContext();
const attrs = useAttrs();

const componentIs = computed(() => {
  if (props.link) {
    if (props.nativeLink && typeof props.link === 'string') {
      return 'a';
    }

    return 'router-link';
  }
  if (props.click) return 'button';

  return 'div';
});

const hasForwardedClick = computed(() => {
  const listener = attrs.onClick;
  if (typeof listener === 'function') return true;
  return Array.isArray(listener) && listener.some(l => typeof l === 'function');
});

const isInteractive = computed(
  () =>
    ['button', 'a', 'router-link'].includes(componentIs.value) ||
    hasForwardedClick.value
);

const triggerClick = () => {
  if (props.click) {
    props.click();
  }
  if (!props.preserveOpen) closeMenu();
};
</script>

<template>
  <li class="n-dropdown-item">
    <component
      :is="componentIs"
      v-bind="$attrs"
      class="flex text-left rtl:text-right items-center p-2 reset-base text-sm text-n-slate-12 w-full border-0"
      :class="{
        'hover:bg-n-alpha-2 rounded-lg w-full gap-3': !$slots.default,
        'cursor-pointer': isInteractive,
      }"
      :href="componentIs === 'a' ? props.link : null"
      :to="componentIs === 'router-link' ? props.link : null"
      @click="triggerClick"
    >
      <slot>
        <slot name="icon">
          <Icon v-if="icon" class="size-4 text-n-slate-11" :icon="icon" />
        </slot>
        <slot name="label">{{ label }}</slot>
      </slot>
    </component>
  </li>
</template>
