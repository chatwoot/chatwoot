<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsHeader from './SettingsHeader.vue';

const props = defineProps({
  headerTitle: { type: String, default: '' },
  headerButtonText: { type: String, default: '' },
  icon: { type: String, default: '' },
  keepAlive: { type: Boolean, default: true },
  newButtonRoutes: { type: Array, default: () => [] },
  showBackButton: { type: Boolean, default: false },
  backUrl: { type: [String, Object], default: '' },
  showSidemenuIcon: { type: Boolean, default: true },
});

const { t } = useI18n();

const showNewButton = computed(
  () => props.newButtonRoutes.length !== 0 && !props.showBackButton
);
</script>

<template>
  <div
    class="flex flex-1 h-full justify-between flex-col m-0 bg-slate-25 dark:bg-slate-900 overflow-auto"
  >
    <SettingsHeader
      button-route="new"
      :icon="icon"
      :header-title="t(headerTitle)"
      :button-text="t(headerButtonText)"
      :show-back-button="showBackButton"
      :back-url="backUrl"
      :show-new-button="showNewButton"
      :show-sidemenu-icon="showSidemenuIcon"
    />
    <router-view v-slot="{ Component }">
      <keep-alive v-if="keepAlive">
        <component :is="Component" />
      </keep-alive>
      <component :is="Component" v-else />
    </router-view>
  </div>
</template>
