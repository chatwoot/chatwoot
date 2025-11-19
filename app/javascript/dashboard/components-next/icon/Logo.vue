<script setup>
import { computed } from 'vue';
import { useAttrs } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { hasCustomBrandAsset } from 'shared/helpers/brandingAssets';

const attrs = useAttrs();
const globalConfig = useMapGetter('globalConfig/get');
const shouldShowLogo = computed(() =>
  hasCustomBrandAsset(globalConfig.value.logoThumbnail)
);
</script>

<template>
  <img
    v-if="shouldShowLogo"
    v-bind="attrs"
    :src="globalConfig.logoThumbnail"
  />
  <div v-else v-bind="attrs" aria-hidden="true"></div>
</template>
