<template>
  <div class="option-item--inbox">
    <span class="badge--icon">
      <fluent-icon :icon="computedInboxIcon" size="14" />
    </span>
    <div class="option__user-data">
      <h5 class="option__title">
        {{ name }}
      </h5>
      <p class="option__body text-truncate" :title="inboxIdentifier">
        {{ inboxIdentifier || computedInboxType }}
      </p>
    </div>
  </div>
</template>

<script>
import {
  getInboxClassByType,
  getReadableInboxByType,
} from 'dashboard/helper/inbox';

export default {
  components: {},
  props: {
    name: {
      type: String,
      default: '',
    },
    inboxIdentifier: {
      type: String,
      default: '',
    },
    channelType: {
      type: String,
      default: '',
    },
  },
  computed: {
    computedInboxIcon() {
      if (!this.channelType) return 'chat';
      const classByType = getInboxClassByType(
        this.channelType,
        this.inboxIdentifier
      );
      return classByType;
    },
    computedInboxType() {
      if (!this.channelType) return 'chat';
      const classByType = getReadableInboxByType(
        this.channelType,
        this.inboxIdentifier
      );
      return classByType;
    },
  },
};
</script>

<style lang="scss" scoped>
.option-item--inbox {
  display: flex;
  align-items: center;
  height: 3.8rem;
  min-width: 0;
  padding: 0 var(--space-smaller);
}
.badge--icon {
  display: inline-flex;
  border-radius: var(--border-radius-small);
  margin-right: var(--space-smaller);
  background: var(--s-25);
  padding: var(--space-micro);
  align-items: center;
  flex-shrink: 0;
  justify-content: center;
  width: var(--space-medium);
  height: var(--space-medium);
}

.option__user-data {
  display: flex;
  flex-direction: column;
  width: 100%;
  min-width: 0;
  margin-left: var(--space-smaller);
  margin-right: var(--space-smaller);
}
.option__body {
  display: inline-block;
  color: var(--s-600);
  font-size: var(--font-size-small);
  line-height: 1.3;
  min-width: 0;
  margin: 0;
}
.option__title {
  line-height: 1.1;
  font-size: var(--font-size-mini);
  margin: 0;
}
</style>
