import { ref } from 'vue';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { useTranslationPlan } from 'dashboard/composables/useTranslationPlan';
import FilterRecommendationsApi from 'dashboard/api/filterRecommendations';
import { buildFiltersFromRecommendations } from './helper/filterHelper';

export const DESCRIBE_STATE = {
  PENDING: 'pending',
  EMPTY: 'empty',
};

const AUTOMATION_FILTER_TYPE = 'automation';

/**
 * Builds filter rows from a description typed into a row's attribute picker.
 * @param {'conversation'|'contact'|'automation'} filterType - What the filters apply to
 * @param {import('vue').ComputedRef<Array>} filterTypes - The filter types the form offers
 * @param {import('vue').Ref<Array>} filters - The filter rows of the form
 * @param {Object} [options]
 * @param {(row: Object) => Object} [options.toRow] - Converts a built row to the form's row shape
 */
export function useFilterRecommendations(
  filterType,
  filterTypes,
  filters,
  { toRow = row => row } = {}
) {
  // Building filters from a description follows the same paid-plan rule as translation.
  const { isAvailable: canDescribeFilters } = useTranslationPlan();
  const { run } = useAbortableRequest();
  // The description being built and its state, shown under the rows. Null when idle.
  const describeStatus = ref(null);

  // Replaces the row the description was typed in with the rows Jev builds.
  // The other rows stay. A failure or an empty result leaves every row as it was.
  const describeFilters = async (index, query) => {
    describeStatus.value = { query, state: DESCRIBE_STATE.PENDING };
    try {
      // An automation event offers its own conditions, so the API only considers those.
      const attributeKeys =
        filterType === AUTOMATION_FILTER_TYPE
          ? filterTypes.value
              .filter(type => type.attributeKey && !type.disabled)
              .map(type => type.attributeKey)
          : undefined;
      const response = await run(signal =>
        FilterRecommendationsApi.create(
          { query, filterType, attributeKeys },
          { signal }
        )
      );
      // A newer description superseded this one and owns the status now.
      if (response === undefined) return;

      const recommendedFilters = buildFiltersFromRecommendations(
        response.data.payload ?? [],
        filterTypes.value
      );
      if (!recommendedFilters.length) {
        describeStatus.value = { query, state: DESCRIBE_STATE.EMPTY };
        return;
      }

      filters.value.splice(index, 1, ...recommendedFilters.map(toRow));
      describeStatus.value = null;
    } catch {
      describeStatus.value = { query, state: DESCRIBE_STATE.EMPTY };
    }
  };

  return { canDescribeFilters, describeStatus, describeFilters };
}
