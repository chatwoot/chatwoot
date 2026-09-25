import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';

const MACROS_ORDER_KEY = 'macros_display_order';

/**
 * Macros in the order the agent arranged them in the sidebar, so every surface
 * that lists them stays in sync. Writing back saves a new order.
 */
export function useOrderedMacros() {
  const { uiSettings, updateUISettings } = useUISettings();
  const macros = useMapGetter('macros/getMacros');

  const orderedMacros = computed({
    get: () => {
      const savedOrder = uiSettings.value?.[MACROS_ORDER_KEY] ?? [];
      const currentMacros = macros.value ?? [];

      if (!savedOrder.length || !currentMacros.length) {
        return currentMacros;
      }

      const orderMap = new Map(savedOrder.map((id, index) => [id, index]));

      // Anything the agent never arranged keeps its store order, at the end
      return [...currentMacros].sort(
        (a, b) =>
          (orderMap.get(a.id) ?? Infinity) - (orderMap.get(b.id) ?? Infinity)
      );
    },
    set: newOrder => {
      updateUISettings({
        [MACROS_ORDER_KEY]: newOrder.map(({ id }) => id),
      });
    },
  });

  return { orderedMacros };
}
