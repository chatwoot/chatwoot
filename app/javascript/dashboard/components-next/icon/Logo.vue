<script setup>
import { useAttrs } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const attrs = useAttrs();
const globalConfig = useMapGetter('globalConfig/get');
</script>

<template>
  <img
    v-if="globalConfig.mainLogo"
    v-bind="attrs"
    :src="globalConfig.mainLogo"
  />
  <svg
    v-else
    v-bind="attrs"
    viewBox="0 0 441 387"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    class="w-full h-full"
  >
    <rect width="386" height="386" rx="193" fill="#2E4AFF" />
    <path
      d="M194.588 285.373C194.588 235.17 233.173 194.483 280.754 194.483V191.517C233.155 191.517 194.588 150.83 194.588 100.627C194.588 99.8262 194.625 99.0438 194.643 98.2432H191.355C191.374 99.0438 191.411 99.8262 191.411 100.627C191.411 150.83 152.825 191.517 105.244 191.517V194.483C152.844 194.483 191.411 235.17 191.411 285.373C191.411 286.174 191.374 286.956 191.355 287.757H194.643C194.625 286.956 194.588 286.174 194.588 285.373Z"
      fill="#E2FF28"
    />
    <path
      d="M441 383.728C368.121 397.226 312.634 358.42 294 337.33L296.07 274.06C316.085 278.278 359.425 282.074 372.676 263.515C370.606 339.439 426.507 377.401 441 383.728Z"
      fill="#2E4AFF"
    />
  </svg>
</template>
