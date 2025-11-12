import type { Ref } from 'vue'
import { onMounted, watch } from 'vue'
import scrollIntoView from 'scroll-into-view-if-needed'

export function useScrollOnActive(active: Ref<boolean>, el: Ref<HTMLElement>) {
  watch(active, (value) => {
    if (value) {
      autoScroll()
    }
  })

  function autoScroll() {
    if (el.value) {
      scrollIntoView(el.value, {
        scrollMode: 'if-needed',
        block: 'center',
        inline: 'nearest',
        behavior: 'smooth',
      })
    }
  }

  onMounted(() => {
    if (active.value) {
      autoScroll()
    }
  })

  return {
    autoScroll,
  }
}
