<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsHeader from './SettingsHeader.vue';
const props = defineProps({
  headerTitle: { type: String, default: '' },
  icon: { type: String, default: '' },
  keepAlive: { type: Boolean, default: true },
  showBackButton: { type: Boolean, default: false },
  backUrl: { type: [String, Object], default: '' },
  fullWidth: { type: Boolean, default: false },
});

const { t } = useI18n();

const showSettingsHeader = computed(
  () => props.headerTitle || props.icon || props.showBackButton
);
</script>

<template>
  <div class="flex flex-1 flex-col m-0 bg-n-surface-1 overflow-auto">
    <div
      class="mx-auto w-full flex flex-col flex-1"
      :class="{ 'max-w-6xl': !fullWidth }"
    >
      <SettingsHeader
        v-if="showSettingsHeader"
        :icon="icon"
        :header-title="t(headerTitle)"
        :show-back-button="showBackButton"
        :back-url="backUrl"
        class="sticky top-0 z-20"
        :class="{ 'max-w-6xl w-full mx-auto': fullWidth }"
      />

      <router-view v-slot="{ Component }" class="px-5 flex-1 overflow-hidden">
        <component :is="Component" v-if="!keepAlive" :key="$route.fullPath" />
        <keep-alive v-else>
          <component :is="Component" :key="$route.fullPath" />
        </keep-alive>
      </router-view>
    </div>
  </div>
</template>
