<template>
  <div class="timeline-card-wrap">
    <div class="icon-chatbox">
      <i class="ion-chatboxes" />
    </div>
    <div class="card-wrap">
      <div class="header">
        <div>
          <span class="event-type">{{ eventType }}</span>
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
import timeMixin from 'dashboard/mixins/time';
export default {
  mixins: [timeMixin],

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
      return this.dynamicTime(this.timeStamp);
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
    justify-content: space-between;
    width: 100%;
    color: var(--color-body);
    padding: var(--space-smaller) var(--space-normal) 0 var(--space-normal);

    .header {
      display: flex;
      padding: 0 0 var(--space-slab) 0;
      justify-content: space-between;

      .event-type {
        font-size: var(--font-size-small);
        font-weight: var(--font-weight-bold);
      }

      .event-path {
        font-size: var(--font-size-mini);
      }

      .date-wrap {
        font-size: var(--font-size-micro);
        padding-top: var(--space-smaller);
      }
    }

    .comment-wrap {
      border: 1px solid var(--color-border-light);

      .comment {
        padding: var(--space-one);
        font-size: var(--font-size-mini);
        margin: 0;
      }
    }
  }

  .icon-more {
    padding: var(--space-micro);
    .ion-android-more-vertical {
      font-size: var(--font-size-medium);
    }
  }
}
</style>
