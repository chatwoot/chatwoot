<script setup>
import { useAttrs } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import newLogo from 'assets/images/app_logo.svg';

const attrs = useAttrs();
const globalConfig = useMapGetter('globalConfig/get');
</script>

<template>
  <img
    v-if="globalConfig.logoThumbnail"
    v-bind="attrs"
    :src="globalConfig.logoThumbnail"
  />
  <img v-else v-bind="attrs" :src="newLogo" alt="DesarrollAndo Asistentes" />
</template>
