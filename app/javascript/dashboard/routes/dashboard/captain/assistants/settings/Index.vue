<script setup>
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAssistantSettings } from './useAssistantSettings';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsPageLayout from 'dashboard/components-next/captain/pageComponents/assistant/settings/SettingsPageLayout.vue';
import AssistantBasicSettingsForm from 'dashboard/components-next/captain/pageComponents/assistant/settings/AssistantBasicSettingsForm.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { assistantId, assistant, updateAssistant } = useAssistantSettings();

const deleteAssistantDialog = ref(null);
const assistants = useMapGetter('captainAssistants/getRecords');

const handleDelete = () => {
  deleteAssistantDialog.value.dialogRef.open();
};

const handleDeleteSuccess = () => {
  // Get remaining assistants after deletion
  const remainingAssistants = assistants.value.filter(
    a => a.id !== assistantId.value
  );

  if (remainingAssistants.length > 0) {
    // Navigate to the first available assistant's settings
    const nextAssistant = remainingAssistants[0];
    router.push({
      name: 'captain_assistants_settings_index',
      params: {
        accountId: route.params.accountId,
        assistantId: nextAssistant.id,
      },
    });
  } else {
    // No assistants left, redirect to create assistant page
    router.push({
      name: 'captain_assistants_create_index',
      params: { accountId: route.params.accountId },
    });
  }
};
</script>

<template>
  <SettingsPageLayout
    :heading="t('CAPTAIN.ASSISTANTS.SETTINGS.BASIC_SETTINGS.TITLE')"
    :description="t('CAPTAIN.ASSISTANTS.SETTINGS.BASIC_SETTINGS.DESCRIPTION')"
  >
    <AssistantBasicSettingsForm
      :assistant="assistant"
      @submit="updateAssistant"
    />
    <span class="w-full h-px mt-2 bg-n-weak" />
    <div class="flex items-end justify-between w-full gap-4">
      <div class="flex flex-col gap-2">
        <h6 class="text-base font-medium text-n-slate-12">
          {{ t('CAPTAIN.ASSISTANTS.SETTINGS.DELETE.TITLE') }}
        </h6>
        <span class="text-sm text-n-slate-11">
          {{ t('CAPTAIN.ASSISTANTS.SETTINGS.DELETE.DESCRIPTION') }}
        </span>
      </div>
      <div class="flex-shrink-0">
        <Button
          :label="
            t('CAPTAIN.ASSISTANTS.SETTINGS.DELETE.BUTTON_TEXT', {
              assistantName: assistant.name,
            })
          "
          color="ruby"
          class="max-w-56 !w-fit"
          @click="handleDelete"
        />
      </div>
    </div>
    <DeleteDialog
      v-if="assistant"
      ref="deleteAssistantDialog"
      :entity="assistant"
      type="Assistants"
      translation-key="ASSISTANTS"
      @delete-success="handleDeleteSuccess"
    />
  </SettingsPageLayout>
</template>
