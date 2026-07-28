import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';

export function useAssistantSettings() {
  const { t } = useI18n();
  const route = useRoute();
  const store = useStore();

  const assistantId = computed(() => Number(route.params.assistantId));
  const assistant = computed(() =>
    store.getters['captainAssistants/getRecord'](assistantId.value)
  );

  const updateAssistant = async updatedAssistant => {
    try {
      await store.dispatch('captainAssistants/update', {
        id: assistantId.value,
        ...updatedAssistant,
      });
      useAlert(t('CAPTAIN.ASSISTANTS.EDIT.SUCCESS_MESSAGE'));
    } catch (error) {
      useAlert(error?.message || t('CAPTAIN.ASSISTANTS.EDIT.ERROR_MESSAGE'));
    }
  };

  return { assistantId, assistant, updateAssistant };
}
