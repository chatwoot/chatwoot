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
  @apply bg-white dark:bg-slate-800 border-slate-75 dark:border-slate-700;
  margin: var(--space-small) !important;

  .card-header--control-area {
    transition: opacity 0.2s ease-in-out;
    @apply opacity-20;
  }

  &:hover {
    .card-header--control-area {
      @apply opacity-100;
    }
  }
}

.card-header {
  grid-template-columns: repeat(auto-fit, minmax(max-content, 50%));
  gap: var(--space-small) 0px;
  @apply grid flex-grow w-full mb-6;

  .card-header--title-area {
    @apply flex items-center flex-row;

    h5 {
      @apply mb-0 text-slate-800 dark:text-slate-100;
    }

    .live {
      background: rgba(37, 211, 102, 0.1);
      @apply flex flex-row items-center pr-2 pl-2 m-1 text-green-400 dark:text-green-400 text-xs;

      .ellipse {
        @apply bg-green-400 dark:bg-green-400 h-1 w-1 rounded-full mr-1 rtl:mr-0 rtl:ml-0;
      }
    }
  }

  .card-header--control-area {
    @apply flex flex-row items-center justify-end gap-2;
  }
}

.card-body {
  .metric-content {
    @apply pb-2;
    .heading {
      @apply text-base text-slate-700 dark:text-slate-100;
    }
    .metric {
      @apply text-woot-800 dark:text-woot-300 text-3xl mb-0 mt-1;
    }
  }
}

.conversation-metric-loader {
  @apply items-center flex text-base justify-center p-12;
}
</style>
