import { computed } from "@histoire/vendors/vue";
import { useRoute } from "@histoire/vendors/vue-router";
"use strict";
function useCurrentVariantRoute(variant) {
  const route = useRoute();
  const isActive = computed(() => route.query.variantId === variant.value.id);
  const targetRoute = computed(() => ({
    ...route,
    query: {
      ...route.query,
      variantId: variant.value.id
    }
  }));
  return {
    isActive,
    targetRoute
  };
}
export {
  useCurrentVariantRoute
};
