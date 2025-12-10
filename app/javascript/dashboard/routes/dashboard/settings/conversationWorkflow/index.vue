<script setup>
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ConversationRequiredAttributes from 'dashboard/components-next/ConversationWorkflow/ConversationRequiredAttributes.vue';
</script>

<template>
  <SettingsLayout :no-records-found="false" class="gap-10">
    <template #header>
      <BaseSettingsHeader
        :title="$t('CONVERSATION_WORKFLOW.INDEX.HEADER.TITLE')"
        :description="$t('CONVERSATION_WORKFLOW.INDEX.HEADER.DESCRIPTION')"
        feature-name="assignment-policy"
      />
    </template>

    <template #body>
      <div class="flex">
        <ConversationRequiredAttributes
          :title="$t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.TITLE')"
          :description="
            $t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.DESCRIPTION')
          "
        />
      </div>
    </template>
  </SettingsLayout>
</template>
