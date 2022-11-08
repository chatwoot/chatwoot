<template>
  <div class="location message-text__wrap">
    <div class="icon-wrap">
      <fluent-icon icon="location" class="file--icon" size="32" />
    </div>
    <div class="meta">
      <h5 class="text-block-title text-truncate">
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
  display: flex;
  flex-direction: row;
  padding: var(--space-smaller) 0;
  cursor: pointer;

  .icon-wrap {
    color: var(--s-600);
    line-height: 1;
    margin: 0 var(--space-smaller);
  }

  .text-block-title {
    margin: 0;
    color: var(--s-800);
    word-break: break-word;
  }

  .meta {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    padding-right: var(--space-normal);
  }

  .link-wrap {
    display: flex;
  }
}
</style>
