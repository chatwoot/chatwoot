import type { Ref } from 'vue'
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import type { Variant } from '../types'

export function useCurrentVariantRoute(variant: Ref<Variant>) {
  const route = useRoute()
  const isActive = computed(() => route.query.variantId === variant.value.id)
  const targetRoute = computed(() => ({
    ...route,
    query: {
      ...route.query,
      variantId: variant.value.id,
    },
  }))

  return {
    isActive,
    targetRoute,
  }
}
