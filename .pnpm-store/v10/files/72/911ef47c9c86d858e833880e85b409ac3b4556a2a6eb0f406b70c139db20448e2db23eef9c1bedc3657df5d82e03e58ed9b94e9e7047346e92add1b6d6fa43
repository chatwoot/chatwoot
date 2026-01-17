<script lang="ts" setup>
import type { CSSProperties } from 'vue'
import HstTokenList from './HstTokenList.vue'

const tokens = {
  '0': 0,
  '1': '0.25rem',
  '2': '0.5rem',
  '3': '0.75rem',
  '4': '1rem',
  '5': '1.25rem',
  '6': '1.5rem',
  '8': '2rem',
  '10': '2.5rem',
  '12': '3rem',
  '16': '4rem',
  '20': '5rem',
  '24': '6rem',
  '32': '8rem',
  '40': '10rem',
  '48': '12rem',
  '56': '14rem',
  '64': '16rem',
  'auto': 'auto',
  'px': '1px',
  'screen': '100vw',
  '1/2': '50%',
  '1/3': '33.333333%',
  '2/3': '66.666667%',
  '1/4': '25%',
  '2/4': '50%',
  '3/4': '75%',
  '1/5': '20%',
  '2/5': '40%',
  '3/5': '60%',
  '4/5': '80%',
  '1/6': '16.666667%',
  '2/6': '33.333333%',
  '3/6': '50%',
  '4/6': '66.666667%',
  '5/6': '83.333333%',
  '1/12': '8.333333%',
  '2/12': '16.666667%',
  '3/12': '25%',
  '4/12': '33.333333%',
  '5/12': '41.666667%',
  '6/12': '50%',
  '7/12': '58.333333%',
  '8/12': '66.666667%',
  '9/12': '75%',
  '10/12': '83.333333%',
  '11/12': '91.666667%',
  'full': '100%',
}
</script>

<template>
  <Story
    title="HstTokenList"
    group="design-system"
    responsive-disabled
  >
    <Variant title="default">
      <HstTokenList
        :tokens="tokens"
        :get-name="key => `w-${key}`"
      >
        <template #default="{ token }">
          <div class="htw-bg-gray-500/10">
            <div
              class="htw-h-20 htw-bg-gray-500/50"
              :style="{
                width: token.value as string,
              } as CSSProperties"
            />
          </div>
        </template>
      </HstTokenList>
    </Variant>
  </Story>
</template>
