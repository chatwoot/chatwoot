<template>
  <div class="timeline-card-wrap">
    <div class="icon-chatbox">
      <i class="ion-chatboxes" />
    </div>
    <div class="card-wrap">
      <div class="header">
        <div class="text-wrap">
          <h6 class="text-sm">
            {{ eventType }}
          </h6>
          <span class="event-path">on {{ eventPath }}</span>
        </div>
        <div class="date-wrap">
          <span>{{ readableTime }}</span>
        </div>
      </div>
      <div class="comment-wrap">
        <p class="comment">
          {{ eventBody }}
        </p>
      </div>
    </div>
    <div class="icon-more" @click="onClick">
      <i class="ion-android-more-vertical" />
    </div>
  </div>
</template>

<script>
import { dynamicTime } from 'shared/helpers/timeHelper';
export default {
  props: {
    eventType: {
      type: String,
      default: '',
    },
    eventPath: {
      type: String,
      default: '',
    },
    eventBody: {
      type: String,
      default: '',
    },
    timeStamp: {
      type: Number,
      default: 0,
    },
  },

  computed: {
    readableTime() {
      return dynamicTime(this.timeStamp);
    },
  },

  methods: {
    onClick() {
      this.$emit('more');
    },
  },
};
</script>

<style lang="scss" scoped>
.timeline-card-wrap {
  display: flex;
  width: 100%;
  color: var(--color-body);
  padding: var(--space-small);

  .icon-chatbox {
    width: var(--space-large);
    height: var(--space-large);
    border-radius: 50%;
    display: flex;
    flex-shrink: 0;
    justify-content: center;
    border: 1px solid var(--color-border);
    background-color: var(--color-background);

    .ion-chatboxes {
      font-size: var(--font-size-default);
      display: flex;
      align-items: center;
    }
  }

  .card-wrap {
    display: flex;
    flex-direction: column;
    width: 100%;
    padding: var(--space-smaller) var(--space-normal) 0;

    .header {
      display: flex;
      justify-content: space-between;

      .text-wrap {
        display: flex;
      }

      .event-path {
        font-size: var(--font-size-mini);
        margin-left: var(--space-smaller);
      }

      .date-wrap {
        font-size: var(--font-size-micro);
      }
    }

    .comment-wrap {
      border: 1px solid var(--color-border-light);

      .comment {
        padding: var(--space-small);
        font-size: var(--font-size-mini);
        margin: 0;
      }
    }
  }

  .icon-more {
    .ion-android-more-vertical {
      font-size: var(--font-size-medium);
    }
  }
}
</style>
