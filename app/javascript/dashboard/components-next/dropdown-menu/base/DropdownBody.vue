<script setup>
import { computed } from 'vue';

const props = defineProps({
  // Use strong prop when this dropdown is stacked inside another dropdown
  // Chrome has issues with stacked backdrop-blur, so we need an extra blur layer when stacked
  // Also, stacked dropdowns should have a strong border
  strong: {
    type: Boolean,
    default: false,
  },
  solidSurface: {
    type: Boolean,
    default: false,
  },
  solidBackgroundColor: {
    type: String,
    default: '',
  },
});

const borderClass = computed(() => {
  return props.strong ? 'border-n-strong' : 'border-n-weak';
});

// Só tratamos como superfície sólida quando há efetivamente uma cor de marca. Sem cor (ex.: tema
// escuro, onde o branding é desligado), voltamos ao surface translúcido padrão em vez de cair num
// azul hardcoded.
const isSolid = computed(
  () => props.solidSurface && Boolean(props.solidBackgroundColor)
);

const surfaceClass = computed(() =>
  isSolid.value ? '' : 'bg-n-alpha-3 backdrop-blur-[100px]'
);

const surfaceStyle = computed(() => {
  if (!isSolid.value) return {};

  return {
    backgroundColor: props.solidBackgroundColor,
    backgroundImage: 'none',
    backdropFilter: 'none',
    WebkitBackdropFilter: 'none',
    opacity: '1',
  };
});

const beforeClass = computed(() => {
  if (!props.strong) return '';

  // Add extra blur layer only when strong prop is true, as a hack for Chrome's stacked backdrop-blur limitation
  // https://issues.chromium.org/issues/40835530
  return "before:content-['\x00A0'] before:absolute before:bottom-0 before:left-0 before:w-full before:h-full before:rounded-xl before:backdrop-contrast-70 before:backdrop-blur-sm before:z-0 [&>*]:relative";
});
</script>

<template>
  <div class="absolute">
    <ul
      class="text-sm border rounded-xl shadow-sm py-2 n-dropdown-body gap-2 grid list-none px-2 reset-base relative"
      :class="[borderClass, beforeClass, surfaceClass]"
      :style="surfaceStyle"
    >
      <slot />
    </ul>
  </div>
</template>
