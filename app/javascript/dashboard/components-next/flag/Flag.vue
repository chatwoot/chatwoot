<script setup>
import { computed } from 'vue';
// Base `.fi` layout only (no url() references): Vite dev hangs when resolving
// relative url(../flags/...) rules in the full flag-icons stylesheet over the
// Docker/WSL bind mount. Each flag SVG is instead loaded directly as an asset
// below, which serves instantly.
import 'assets/css/flag-icons-base.css';

const props = defineProps({
  country: { type: String, required: true },
  squared: { type: Boolean, default: false },
});

const flagAssets = import.meta.glob('../../assets/flags/*/*.svg', {
  eager: true,
  query: '?url',
  import: 'default',
});

const backgroundImage = computed(() => {
  const sizeDir = props.squared ? '1x1' : '4x3';
  const flagPath = `../../assets/flags/${sizeDir}/${props.country.toLowerCase()}.svg`;
  const flagUrl = flagAssets[flagPath];
  return flagUrl ? `url(${flagUrl})` : undefined;
});
</script>

<template>
  <span
    class="fi flex-shrink-0"
    :class="{ fis: squared }"
    :style="{ backgroundImage }"
  />
</template>
