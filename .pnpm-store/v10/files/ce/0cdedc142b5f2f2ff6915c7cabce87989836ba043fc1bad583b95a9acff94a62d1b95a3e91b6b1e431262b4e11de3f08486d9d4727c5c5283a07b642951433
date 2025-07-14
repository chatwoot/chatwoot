import type { Ref } from 'vue'
import { computed, ref, watch } from 'vue'

export function useSelection(list: Ref<any[]>) {
  const selectedIndex = ref(0)

  watch(list, () => {
    selectedIndex.value = 0
  })

  function selectNext() {
    selectedIndex.value++
    if (selectedIndex.value > list.value.length - 1) {
      selectedIndex.value = 0
    }
  }

  function selectPrevious() {
    selectedIndex.value--
    if (selectedIndex.value < 0) {
      selectedIndex.value = list.value.length - 1
    }
  }

  return {
    selectedIndex: computed(() => selectedIndex.value),
    selectNext,
    selectPrevious,
  }
}
