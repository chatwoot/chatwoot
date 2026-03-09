<script setup>
import SettingsHeader from './SettingsHeader.vue';
</script>

<template>
  <Story
    title="Captain/PageComponents/SettingsHeader"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Default">
      <div class="px-6 py-4 bg-n-background">
        <SettingsHeader
          heading="General Settings"
          description="Configure general preferences for your workspace."
        />
      </div>
    </Variant>

    <Variant title="Long Description">
      <div class="px-6 py-4 bg-n-background">
        <SettingsHeader
          heading="Integrations"
          description="Manage and configure third-party integrations such as Slack, Zapier, and Webhooks to enhance your workflow."
        />
      </div>
    </Variant>
  </Story>
</template>
