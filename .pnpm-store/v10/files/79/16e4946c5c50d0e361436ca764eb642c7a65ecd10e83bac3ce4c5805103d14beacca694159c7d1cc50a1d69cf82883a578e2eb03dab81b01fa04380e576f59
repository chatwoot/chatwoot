<script lang="ts" setup>
import type { PropType } from 'vue'
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import GenericRenderStory from '../story/GenericRenderStory.vue'
import type { Story, Variant } from '../../types'
import BaseEmpty from '../base/BaseEmpty.vue'
import StatePresets from './StatePresets.vue'
import ControlsComponentProps from './ControlsComponentProps.vue'
import ControlsComponentState from './ControlsComponentState.vue'

const props = defineProps({
  variant: {
    type: Object as PropType<Variant>,
    required: true,
  },

  story: {
    type: Object as PropType<Story>,
    required: true,
  },
})

// Wait for controls render before applying presets
const ready = ref(false)

watch(() => props.variant, () => {
  ready.value = false
})

const hasCustomControls = computed(() => props.variant.slots().controls || props.story.slots().controls)

const hasInitState = computed(() => Object
  .entries(props.variant.state || {})
  .filter(([key]) => !key.startsWith('_h'))
  .length > 0)
</script>

<template>
  <div
    data-test-id="story-controls"
    class="histoire-story-controls htw-flex htw-flex-col htw-divide-y htw-divide-gray-100 dark:htw-divide-gray-750"
  >
    <!-- Toolbar -->
    <div
      class="htw-h-9 htw-flex-none htw-px-2 htw-flex htw-items-center"
    >
      <StatePresets
        v-if="ready || !hasCustomControls"
        :story="story"
        :variant="variant"
      />
    </div>

    <!-- Custom controls -->
    <GenericRenderStory
      v-if="hasCustomControls"
      :key="`${story.id}-${variant.id}`"
      slot-name="controls"
      :variant="variant"
      :story="story"
      class="__histoire-render-custom-controls htw-flex-none"
      @ready="ready = true"
    />

    <!-- Init state -->
    <div
      v-else-if="hasInitState"
    >
      <ControlsComponentState
        class="htw-flex-none htw-my-2"
        :variant="variant"
      />
    </div>

    <BaseEmpty v-else-if="!variant.state?._hPropDefs?.length">
      <Icon
        icon="carbon:audio-console"
        class="htw-w-8 htw-h-8 htw-opacity-50 htw-mb-6"
      />
      <span>No controls available for this story</span>
    </BaseEmpty>

    <!-- Auto props -->
    <div
      v-if="variant.state?._hPropDefs?.length"
    >
      <ControlsComponentProps
        v-for="(def, index) of variant.state._hPropDefs"
        :key="index"
        :variant="variant"
        :definition="def"
        class="htw-flex-none htw-my-2"
      />
    </div>
  </div>
</template>
