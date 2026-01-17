<script lang="ts" setup>
import { computed } from 'vue'
import { isDark } from '../../util/dark'
import { customLogos, histoireConfig } from '../../util/config'

import HistoireLogoDark from '../../assets/histoire-text-dark.svg'
import HistoireLogoLight from '../../assets/histoire-text.svg'

const logoUrl = computed(() => {
  if (isDark.value) {
    return histoireConfig.theme.logo?.dark ? customLogos.dark : HistoireLogoDark
  }
  return histoireConfig.theme.logo?.light ? customLogos.light : HistoireLogoLight
})

const altText = computed(() => `${histoireConfig.theme.title} logo`)
</script>

<template>
  <img
    class="histoire-app-logo"
    :src="logoUrl"
    :alt="altText"
  >
</template>
