<template>
  <div v-on-clickaway="onClose" class="labels-container">
    <div class="triangle">
      <svg height="12" viewBox="0 0 24 12" width="24">
        <path d="M20 12l-8-8-12 12" fill-rule="evenodd" stroke-width="1px" />
      </svg>
    </div>
    <div class="header flex items-center justify-between">
      <span>{{ $t('BULK_ACTION.LABELS.ASSIGN_LABELS') }}</span>
      <woot-button
        size="tiny"
        variant="clear"
        color-scheme="secondary"
        icon="dismiss"
        @click="onClose"
      />
    </div>
    <div class="labels-list">
      <header class="labels-list__header">
        <div
          class="label-list-search h-8 flex justify-between items-center gap-2"
        >
          <fluent-icon icon="search" class="search-icon" size="16" />
          <input
            ref="search"
            v-model="query"
            type="search"
            placeholder="Search"
            class="label--search_input"
          />
        </div>
      </header>
      <ul class="labels-list__body">
        <li
          v-for="label in filteredLabels"
          :key="label.id"
          class="label__list-item"
        >
          <label
            class="item"
            :class="{ 'label-selected': isLabelSelected(label.title) }"
          >
            <input
              v-model="selectedLabels"
              type="checkbox"
              :value="label.title"
              class="label-checkbox"
            />
            <span
              class="label-title overflow-hidden whitespace-nowrap text-ellipsis"
            >
              {{ label.title }}
            </span>
            <span
              class="label-pill"
              :style="{ backgroundColor: label.color }"
            />
          </label>
        </li>
      </ul>
      <footer class="labels-list__footer">
        <woot-button
          size="small"
          is-expanded
          color-scheme="primary"
          :disabled="!selectedLabels.length"
          @click="$emit('assign', selectedLabels)"
        >
          <span>{{ $t('BULK_ACTION.LABELS.ASSIGN_SELECTED_LABELS') }}</span>
        </woot-button>
      </footer>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  data() {
    return {
      query: '',
      selectedLabels: [],
    };
  },
  computed: {
    ...mapGetters({ labels: 'labels/getLabels' }),
    filteredLabels() {
      return this.labels.filter(label =>
        label.title.toLowerCase().includes(this.query.toLowerCase())
      );
    },
  },
  methods: {
    isLabelSelected(label) {
      return this.selectedLabels.includes(label);
    },
    assignLabels(key) {
      this.$emit('update', key);
    },
    onClose() {
      this.$emit('close');
    },
  },
};
</script>

<style scoped lang="scss">
.labels-list {
  @apply flex flex-col max-h-[15rem] min-h-[auto];

  .labels-list__header {
    @apply bg-white dark:bg-slate-800 py-0 px-2.5;
  }

  .labels-list__body {
    @apply flex-1 overflow-y-auto py-2.5 mx-0;
  }

  .labels-list__footer {
    @apply p-2;

    button {
      @apply w-full;

      .button__content {
        @apply text-center;
      }
    }
  }
}

.label-list-search {
  @apply bg-slate-50 dark:bg-slate-900 py-0 px-2.5 border border-solid border-slate-100 dark:border-slate-600/70 rounded-md;

  .search-icon {
    @apply text-slate-400 dark:text-slate-200;
  }

  .label--search_input {
    @apply border-0 text-xs m-0 dark:bg-transparent bg-transparent h-[unset] w-full;
  }
}

.labels-container {
  @apply absolute right-2 top-12 origin-top-right w-auto z-20 max-w-[15rem] min-w-[15rem] bg-white dark:bg-slate-800 rounded-lg border border-solid border-slate-50 dark:border-slate-700 shadow-md;

  .header {
    @apply p-2.5;

    span {
      @apply text-sm font-medium;
    }
  }

  .container {
    @apply max-h-[15rem] overflow-y-auto;

    .label__list-container {
      @apply h-full;
    }
  }

  .triangle {
    right: var(--triangle-position);
    @apply block z-10 absolute text-left -top-3;

    svg path {
      @apply fill-white dark:fill-slate-800 stroke-slate-50 dark:stroke-slate-600/50;
    }
  }
}

ul {
  @apply m-0 list-none;
}

.labels-placeholder {
  @apply p-2;
}

.label__list-item {
  @apply my-1 mx-0 py-0 px-2.5;

  .item {
    @apply items-center rounded-md cursor-pointer flex py-1 px-2.5 hover:bg-slate-50 dark:hover:bg-slate-900;

    &.label-selected {
      @apply bg-slate-50 dark:bg-slate-900;
    }

    span {
      @apply text-sm;
    }

    .label-checkbox {
      @apply my-0 mr-2.5 ml-0;
    }

    .label-title {
      @apply flex-grow w-full;
    }

    .label-pill {
      @apply bg-slate-50 rounded-md h-3 w-3 flex-shrink-0 border border-solid border-slate-50 dark:border-slate-900;
    }
  }
}

.search-container {
  @apply bg-white py-0 px-2.5 sticky top-0 z-20;
}

.actions-container {
  @apply bg-white dark:bg-slate-900 bottom-0 p-2 sticky z-20;

  button {
    @apply w-full;
  }
}
</style>
