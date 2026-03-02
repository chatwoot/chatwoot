<script setup>
import { useAttrs } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const attrs = useAttrs();
const globalConfig = useMapGetter('globalConfig/get');
</script>

<template>
  <img
    v-bind="attrs"
    :src="globalConfig.logoThumbnail || '/brand-assets/logo_thumbnail.svg'"
  />
</template>
