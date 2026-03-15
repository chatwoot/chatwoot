<script setup>
import { useAttrs } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const attrs = useAttrs();
const globalConfig = useMapGetter('globalConfig/get');
</script>

<template>
  <img
    v-if="globalConfig.logoThumbnail"
    v-bind="attrs"
    :src="globalConfig.logoThumbnail"
  />
  <svg
    v-else
    v-once
    v-bind="attrs"
    width="16"
    height="16"
    viewBox="0 0 1025 1025"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path
      d="M0 129C0 58.3076 57.3076 1 128 1H256V1025H128C57.3076 1025 0 967.692 0 897V129Z"
      fill="#fff"
    />
    <path
      d="M385 1C385 0.447715 385.448 0 386 0H641V1024H385V1Z"
      fill="#fff"
    />
    <path
      d="M769 1.00002C769 0.447738 769.448 0 770 0H897C967.692 0 1025 57.3076 1025 128V896H897C826.308 896 769 838.692 769 768V1.00002Z"
      fill="#fff"
    />
  </svg>
</template>
