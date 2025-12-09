import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useOperators } from 'dashboard/components-next/filter/operators';
import { useMapGetter } from 'dashboard/composables/store.js';

/**
 * Provider simplificado de filtros para Kanban
 * Apenas 2 filtros: Etiquetas e Times
 */
export function useKanbanFilterContext() {
  const { t } = useI18n();

  const labels = useMapGetter('labels/getLabels');
  const teams = useMapGetter('teams/getTeams');

  const { equalityOperators } = useOperators();

  const filterTypes = computed(() => [
    {
      attributeKey: 'labels',
      value: 'labels',
      attributeName: t('CONTACTS_FILTER.ATTRIBUTES.LABELS'),
      label: t('CONTACTS_FILTER.ATTRIBUTES.LABELS'),
      inputType: 'multiSelect',
      options:
        labels.value?.map(label => ({
          id: label.title,
          name: label.title,
        })) || [],
      dataType: 'text',
      filterOperators: equalityOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'team_id',
      value: 'team_id',
      attributeName: t('FILTER.ATTRIBUTES.TEAM_NAME'),
      label: t('FILTER.ATTRIBUTES.TEAM_NAME'),
      inputType: 'searchSelect',
      options: teams.value || [],
      dataType: 'number',
      filterOperators: equalityOperators.value,
      attributeModel: 'standard',
    },
  ]);

  return { filterTypes };
}
