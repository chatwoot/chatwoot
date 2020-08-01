<template>
  <div class="message-text--metadata">
    <span class="time">{{ readableTime }}</span>
    <i
      v-if="isEmail"
      v-tooltip.top-start="$t('CHAT_LIST.RECEIVED_VIA_EMAIL')"
      class="ion ion-android-mail"
    />
    <i
      v-if="isPrivate"
      v-tooltip.top-start="$t('CONVERSATION.VISIBLE_TO_AGENTS')"
      class="icon ion-android-lock"
      @mouseenter="isHovered = true"
      @mouseleave="isHovered = false"
    />
  </div>
</template>

<script>
export default {
  props: {
    readableTime: {
      type: String,
      default: '',
    },
    isEmail: {
      type: Boolean,
      default: true,
    },
    isPrivate: {
      type: Boolean,
      default: true,
    },
  },
};
</script>

<style lang="scss" scoped>
.right {
  .message-text--metadata {
    .time {
      color: var(--w-100);
    }
  }
}

.left {
  .message-text--metadata {
    .time {
      color: var(--s-400);
    }
  }
}

.message-text--metadata {
  align-items: flex-end;
  display: flex;

  .time {
    margin-right: var(--space-small);
    display: block;
    font-size: var(--font-size-micro);
    line-height: 1.8;
  }

  i {
    line-height: 1.4;
  }
}

.activity-wrap {
  .message-text--metadata {
    display: inline-block;

    .time {
      color: var(--s-300);
      font-size: var(--font-size-micro);
      margin-left: var(--space-small);
    }
  }
}

.is-image {
  .message-text--metadata {
    .time {
      bottom: var(--space-smaller);
      color: var(--white);
      position: absolute;
      right: var(--space-small);
      white-space: nowrap;
    }
  }
}

.is-private {
  .message-text--metadata {
    align-items: flex-end;

    .time {
      color: var(--s-400);
    }
  }

  &.is-image {
    .time {
      position: inherit;
      padding-left: var(--space-one);
    }
  }
}
</style>
