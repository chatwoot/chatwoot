<script setup>
import PortalSettings from '../../components-next/HelpCenter/Pages/PortalSettingsPage/PortalSettings.vue';
</script>

<template>
  <Story title="HelpCenter/PortalSettingsPage" :layout="{ type: 'single' }">
    <Variant title="Default">
      <div class="w-[1000px] min-h-screen bg-white dark:bg-slate-900">
        <PortalSettings />
      </div>
    </Variant>
  </Story>
</template>
