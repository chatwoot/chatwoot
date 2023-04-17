<template>
  <div class="card">
    <div class="card-header">
      <slot name="header">
        <div class="card-header--title-area">
          <h5>{{ header }}</h5>
          <span class="live">
            <span class="ellipse" /><span>{{
              $t('OVERVIEW_REPORTS.LIVE')
            }}</span>
          </span>
        </div>
        <div class="card-header--control-area">
          <slot name="control" />
        </div>
      </slot>
    </div>
    <div v-if="!isLoading" class="card-body row">
      <slot />
    </div>
    <div v-else-if="isLoading" class="conversation-metric-loader">
      <spinner />
      <span>{{ loadingMessage }}</span>
    </div>
  </div>
</template>
<script>
import Spinner from 'shared/components/Spinner.vue';

export default {
  name: 'MetricCard',
  components: {
    Spinner,
  },
  props: {
    header: {
      type: String,
      default: '',
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    loadingMessage: {
      type: String,
      default: '',
    },
  },
};
</script>
<style lang="scss" scoped>
.card {
  margin: var(--space-small) !important;

  .card-header--control-area {
    opacity: 0.2;
    transition: opacity 0.2s ease-in-out;
  }

  &:hover {
    .card-header--control-area {
      opacity: 1;
    }
  }
}

.card-header {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(max-content, 50%));
  gap: var(--space-small) 0px;
  flex-grow: 1;
  width: 100%;
  margin-bottom: var(--space-medium);

  .card-header--title-area {
    display: flex;
    flex-direction: row;
    align-items: center;

    h5 {
      margin-bottom: var(--zero);
    }

    .live {
      display: flex;
      flex-direction: row;
      align-items: center;
      padding-right: var(--space-small);
      padding-left: var(--space-small);
      margin: var(--space-smaller);
      background: rgba(37, 211, 102, 0.1);
      color: var(--g-400);
      font-size: var(--font-size-mini);

      .ellipse {
        background-color: var(--g-400);
        height: var(--space-smaller);
        width: var(--space-smaller);
        border-radius: var(--border-radius-rounded);
        margin-right: var(--space-smaller);
      }
    }
  }

  .card-header--control-area {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: end;
    gap: var(--space-small);
  }
}

.card-body {
  .metric-content {
    padding-bottom: var(--space-small);
    .heading {
      font-size: var(--font-size-default);
    }
    .metric {
      color: var(--w-800);
      font-size: var(--font-size-bigger);
      margin-bottom: var(--zero);
      margin-top: var(--space-smaller);
    }
  }
}

.conversation-metric-loader {
  align-items: center;
  display: flex;
  font-size: var(--font-size-default);
  justify-content: center;
  padding: var(--space-large);
}
</style>
