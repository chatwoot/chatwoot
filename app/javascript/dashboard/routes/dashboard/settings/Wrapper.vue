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

const headerClass = computed(() =>
  props.fullWidth ? 'z-20 w-full' : 'z-20 max-w-7xl w-full mx-auto'
);

const viewClass = computed(() =>
  props.fullWidth
    ? 'flex-1 min-h-0 overflow-hidden px-0'
    : 'px-4 overflow-hidden'
);
</script>

<template>
  <div class="flex flex-col h-full m-0 bg-n-surface-1 w-full">
    <SettingsHeader
      v-if="showSettingsHeader"
      :icon="icon"
      :header-title="t(headerTitle)"
      :show-back-button="showBackButton"
      :back-url="backUrl"
      :class="headerClass"
    />

    <router-view v-slot="{ Component }" :class="viewClass">
      <component :is="Component" v-if="!keepAlive" :key="$route.fullPath" />
      <keep-alive v-else>
        <component :is="Component" :key="$route.fullPath" />
      </keep-alive>
    </router-view>
  </div>
</template>
