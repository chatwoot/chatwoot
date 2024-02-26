<template>
  <div class="location message-text__wrap">
    <div class="icon-wrap">
      <fluent-icon icon="location" class="file--icon" size="32" />
    </div>
    <div class="meta">
      <h5
        class="text-sm text-slate-800 dark:text-slate-100 overflow-hidden whitespace-nowrap text-ellipsis"
      >
        {{ name }}
      </h5>
      <div class="link-wrap">
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

<script>
export default {
  props: {
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
  },
  computed: {
    mapUrl() {
      return `https://maps.google.com/?q=${this.latitude},${this.longitude}`;
    },
  },
};
</script>

<style lang="scss" scoped>
.location {
  @apply flex flex-row py-1 px-0 cursor-pointer;

  .icon-wrap {
    @apply text-slate-600 dark:text-slate-200 leading-none my-0 mx-1;
  }

  .text-block-title {
    @apply m-0 text-slate-800 dark:text-slate-100 break-words;
  }

  .meta {
    @apply flex flex-col items-center pr-4;
  }

  .link-wrap {
    @apply flex;
  }
}
</style>
