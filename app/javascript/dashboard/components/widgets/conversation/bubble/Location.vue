<script setup>
import { computed } from 'vue';

const props = defineProps({
  latitude: {
    type: Number,
    default: undefined,
  },
  longitude: {
    type: Number,
    default: undefined,
  },
  name: {
    type: String,
    default: '',
  },
});

const mapUrl = computed(
  () => `https://maps.google.com/?q=${props.latitude},${props.longitude}`
);
</script>

<template>
  <div
    class="flex flex-row items-center justify-start gap-1 w-full py-1 px-0 cursor-pointer overflow-hidden"
  >
    <fluent-icon
      icon="location"
      class="text-slate-600 dark:text-slate-200 leading-none my-0 flex items-center flex-shrink-0"
      size="32"
    />
    <div class="flex flex-col items-start flex-1 min-w-0">
      <h5
        class="text-sm text-slate-800 dark:text-slate-100 truncate m-0 w-full"
        :title="name"
      >
        {{ name }}
      </h5>
      <div class="flex items-center">
        <a
          class="text-woot-600 dark:text-woot-600 text-xs underline"
          rel="noreferrer noopener nofollow"
          target="_blank"
          :href="mapUrl"
        >
          {{ $t('COMPONENTS.LOCATION_BUBBLE.SEE_ON_MAP') }}
        </a>
      </div>
    </div>
  </div>
</template>
