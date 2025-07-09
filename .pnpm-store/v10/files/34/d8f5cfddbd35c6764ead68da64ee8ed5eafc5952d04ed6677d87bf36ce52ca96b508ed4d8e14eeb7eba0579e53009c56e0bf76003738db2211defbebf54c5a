<script lang="ts" setup>
import type { PropType } from 'vue'
import { ref, toRefs } from 'vue'
import { useRouter } from 'vue-router'
import type { SearchResult } from '../../types'
import { onKeyboardShortcut } from '../../util/keyboard'
import { useScrollOnActive } from '../../util/scroll'
import BaseListItemLink from '../base/BaseListItemLink.vue'
import BaseListItem from '../base/BaseListItem.vue'
import SearchItemContent from './SearchItemContent.vue'

const props = defineProps({
  result: {
    type: Object as PropType<SearchResult>,
    required: true,
  },

  selected: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits({
  close: () => true,
})

const el = ref<HTMLDivElement>()

const { selected } = toRefs(props)
useScrollOnActive(selected, el)

const router = useRouter()

onKeyboardShortcut(['enter'], () => {
  if (!props.selected) return
  action()
})

function action(fromClick = false) {
  if ('route' in props.result && !fromClick) {
    router.push(props.result.route)
  }
  if ('onActivate' in props.result) {
    props.result.onActivate()
  }
  emit('close')
}
</script>

<template>
  <div
    ref="el"
    class="histoire-search-item"
    data-test-id="search-item"
    :data-selected="selected ? '' : undefined"
  >
    <BaseListItemLink
      v-if="'route' in result"
      :to="result.route"
      :is-active="selected"
      class="htw-px-6 htw-py-4 htw-gap-4"
      @navigate="action(true)"
    >
      <SearchItemContent
        :result="result"
        :selected="selected"
      />
    </BaseListItemLink>

    <BaseListItem
      v-if="'onActivate' in result"
      :is-active="selected"
      class="htw-px-6 htw-py-4 htw-gap-4"
      @navigate="action(true)"
    >
      <SearchItemContent
        :result="result"
        :selected="selected"
      />
    </BaseListItem>
  </div>
</template>

<style scoped>
.bind-icon-color {
  color: v-bind('result.iconColor');
}
</style>
