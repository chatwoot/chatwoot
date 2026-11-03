import { ref } from 'vue';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { useTranslationPlan } from 'dashboard/composables/useTranslationPlan';
import FilterRecommendationsApi from 'dashboard/api/filterRecommendations';
import { buildFiltersFromRecommendations } from './helper/filterHelper';

export const DESCRIBE_STATE = {
  PENDING: 'pending',
  EMPTY: 'empty',
};

/**
 * Builds filter rows from a description typed into a row's attribute picker.
 * @param {'conversation'|'contact'} filterType - The records the filters apply to
 * @param {import('vue').ComputedRef<Array>} filterTypes - The filter types the form offers
 * @param {import('vue').Ref<Array>} filters - The filter rows of the form
 */
export function useFilterRecommendations(filterType, filterTypes, filters) {
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
      const response = await run(signal =>
        FilterRecommendationsApi.create(query, filterType, { signal })
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

      filters.value.splice(index, 1, ...recommendedFilters);
      describeStatus.value = null;
    } catch {
      describeStatus.value = { query, state: DESCRIBE_STATE.EMPTY };
    }
  };

  return { canDescribeFilters, describeStatus, describeFilters };
}
