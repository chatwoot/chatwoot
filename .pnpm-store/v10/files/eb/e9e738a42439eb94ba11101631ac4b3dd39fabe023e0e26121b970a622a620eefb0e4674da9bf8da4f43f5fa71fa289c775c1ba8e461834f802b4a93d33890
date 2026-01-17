<script lang="ts">
export default {
  name: 'HstTokenList',
}
</script>

<script lang="ts" setup>
import { computed, ref } from 'vue'
import HstCopyIcon from '../HstCopyIcon.vue'

const props = defineProps<{
  tokens: Record<string, string | number | any[] | Record<string, any>>
  getName?: (key: string, value: string | number | any[] | Record<string, any>) => string
}>()

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

const hover = ref<string>(null)
</script>

<template>
  <div
    v-for="token of processedTokens"
    :key="token.key"
    class="histoire-token-list htw-flex htw-flex-col htw-gap-2 htw-my-8"
    @mouseenter="hover = token.key"
    @mouseleave="hover = null"
  >
    <slot
      :token="token"
    />
    <div class="htw-mx-4">
      <div class="htw-flex htw-gap-1">
        <pre class="htw-my-0 htw-truncate htw-shrink">{{ token.name }}</pre>
        <HstCopyIcon
          v-if="hover === token.key"
          :content="token.name"
          class="htw-flex-none"
        />
      </div>
      <div class="htw-flex htw-gap-1">
        <pre class="htw-my-0 htw-opacity-50 htw-truncate htw-shrink">{{ token.value }}</pre>
        <HstCopyIcon
          v-if="hover === token.key"
          :content="typeof token.value === 'string' ? token.value : JSON.stringify(token.value)"
          class="htw-flex-none"
        />
      </div>
    </div>
  </div>
</template>
