<script setup>
import { computed, toRefs } from 'vue';

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

const { latitude, longitude, name } = toRefs(props);

const mapUrl = computed(
  () => `https://maps.google.com/?q=${latitude.value},${longitude.value}`
);
</script>

<template>
  <div
    class="location message-text__wrap flex flex-row items-center justify-start gap-1 w-full py-1 px-0 cursor-pointer overflow-hidden"
  >
    <fluent-icon
      icon="location"
      class="file--icon text-slate-600 dark:text-slate-200 leading-none my-0 flex items-center flex-shrink-0"
      size="32"
    />
    <div class="flex flex-col items-start w-11/12">
      <h5
        class="text-sm text-slate-800 dark:text-slate-100 overflow-hidden whitespace-nowrap text-ellipsis m-0 w-full"
        :title="name"
      >
        {{ name }}
      </h5>
      <div class="flex items-center">
        <a
          class="download clear link button small"
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
