import { ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

/**
 * Composable to interact with custom attribute definitions:
 *  - Recalculate (manually trigger recompute of formula values)
 *  - Preview (compute the formula value with a sample, without persisting)
 */
export function useCustomAttributeDefinitionActions() {
  const store = useStore();
  const { t } = useI18n();
  const isRecalculating = ref(false);
  const isPreviewing = ref(false);
  const lastPreview = ref(null);

  const recalculate = async definitionId => {
    isRecalculating.value = true;
    try {
      await store.dispatch('attributes/recalculate', definitionId);
      useAlert(
        t('ATTRIBUTES_SETTINGS.RECOMPUTE.REQUEST_ACCEPTED') ||
          'Recompute queued successfully'
      );
    } catch (error) {
      useAlert(
        error?.message ||
          t('ATTRIBUTES_SETTINGS.RECOMPUTE.ERROR') ||
          'Unable to recompute'
      );
    } finally {
      isRecalculating.value = false;
    }
  };

  const preview = async (definitionId, sampleAttributes = {}) => {
    isPreviewing.value = true;
    try {
      const result = await store.dispatch('attributes/preview', {
        id: definitionId,
        sampleAttributes,
      });
      lastPreview.value = result;
      return result;
    } catch (error) {
      useAlert(error?.message || 'Unable to compute preview');
      return null;
    } finally {
      isPreviewing.value = false;
    }
  };

  return {
    isRecalculating,
    isPreviewing,
    lastPreview,
    recalculate,
    preview,
  };
}
