import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useFunctionGetter } from 'dashboard/composables/store';

export function useAssistantSettings() {
  const { t } = useI18n();
  const route = useRoute();
  const store = useStore();

  const assistantId = computed(() => Number(route.params.assistantId));
  const assistant = useFunctionGetter(
    'captainAssistants/getRecord',
    assistantId
  );

  const fetchAssistant = () =>
    store.dispatch('captainAssistants/show', assistantId.value);

  const updateAssistant = async updatedAssistant => {
    try {
      const savedAssistant = await store.dispatch('captainAssistants/update', {
        id: assistantId.value,
        ...updatedAssistant,
      });
      useAlert(t('CAPTAIN.ASSISTANTS.EDIT.SUCCESS_MESSAGE'));
      return savedAssistant;
    } catch (error) {
      useAlert(error?.message || t('CAPTAIN.ASSISTANTS.EDIT.ERROR_MESSAGE'));
      return undefined;
    }
  };

  return { assistantId, assistant, fetchAssistant, updateAssistant };
}
