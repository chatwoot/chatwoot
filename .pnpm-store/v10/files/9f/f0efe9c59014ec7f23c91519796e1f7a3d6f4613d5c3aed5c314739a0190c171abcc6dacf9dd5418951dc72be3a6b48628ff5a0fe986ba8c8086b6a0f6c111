<script lang="ts">
export default {
  name: 'HstTokenGrid',
}
</script>

<script lang="ts" setup>
import { computed, ref, withDefaults } from 'vue'
import { VTooltip as vTooltip } from 'floating-vue'
import HstCopyIcon from '../HstCopyIcon.vue'

const props = withDefaults(defineProps<{
  tokens: Record<string, string | number | any[] | Record<string, any>>
  colSize?: number
  getName?: (key: string, value: string | number | any[] | Record<string, any>) => string
}>(), {
  colSize: 180,
  getName: null,
})

const processedTokens = computed(() => {
  const list = props.tokens
  const getName = props.getName
  return Object.entries(list).map(([key, value]) => {
    const name = getName ? getName(key, value) : key
    return {
      key,
      name,
      value: typeof value === 'number' ? value.toString() : value,
    }
  })
})

const colSizePx = computed(() => `${props.colSize}px`)

const hover = ref<string>(null)
</script>

<template>
  <div
    class="histoire-token-grid htw-bind-col-size htw-grid htw-gap-4 htw-m-4"
    :style="{
      '--histoire-col-size': colSizePx,
    }"
  >
    <div
      v-for="token of processedTokens"
      :key="token.key"
      class="htw-flex htw-flex-col htw-gap-2"
      @mouseenter="hover = token.key"
      @mouseleave="hover = null"
    >
      <slot
        :token="token"
      />
      <div>
        <div class="htw-flex htw-gap-1">
          <pre
            v-tooltip="token.name.length > colSize / 8 ? token.name : ''"
            class="htw-my-0 htw-truncate htw-shrink"
          >{{ token.name }}</pre>
          <HstCopyIcon
            v-if="hover === token.key"
            :content="token.name"
            class="htw-flex-none"
          />
        </div>
        <div class="htw-flex htw-gap-1">
          <pre
            v-tooltip="token.value.length > colSize / 8 ? token.value : ''"
            class="htw-my-0 htw-opacity-50 htw-truncate htw-shrink"
          >{{ token.value }}</pre>
          <HstCopyIcon
            v-if="hover === token.key"
            :content="typeof token.value === 'string' ? token.value : JSON.stringify(token.value)"
            class="htw-flex-none"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<style>
.htw-bind-col-size {
  grid-template-columns: repeat(auto-fill, minmax(var(--histoire-col-size), 1fr));
}
</style>
