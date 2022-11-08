<template>
  <div class="location message-text__wrap">
    <div class="icon-wrap">
      <fluent-icon icon="location" class="file--icon" size="32" />
    </div>
    <div class="meta">
      <h5 class="text-block-title text-truncate">
        {{ name }}
      </h5>
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
    color: var(--white);
    line-height: 1;
    margin: 0 var(--space-smaller);
  }

  .text-block-title {
    margin: 0;
    color: var(--white);
    word-break: break-word;
  }

  .button {
    color: var(--s-25);
  }

  .meta {
    padding-right: var(--space-normal);
  }
}
</style>
