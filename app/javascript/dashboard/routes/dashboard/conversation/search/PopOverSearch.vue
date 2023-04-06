<template>
  <div class="search-wrap">
    <div class="search" :class="{ 'is-active': showSearchBox }">
      <woot-sidemenu-icon />
      <router-link :to="searchUrl" class="search--link">
        <div class="icon">
          <fluent-icon icon="search" class="search--icon" size="16" />
        </div>
        <p class="search--label">{{ $t('CONVERSATION.SEARCH_MESSAGES') }}</p>
      </router-link>
      <switch-layout
        :is-on-expanded-layout="isOnExpandedLayout"
        @toggle="$emit('toggle-conversation-layout')"
      />
    </div>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { mapGetters } from 'vuex';
import timeMixin from '../../../../mixins/time';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import SwitchLayout from './SwitchLayout.vue';
import { frontendURL } from 'dashboard/helper/URLHelper';
export default {
  components: {
    SwitchLayout,
  },
  directives: {
    focus: {
      inserted(el) {
        el.focus();
      },
    },
  },
  mixins: [timeMixin, messageFormatterMixin, clickaway],
  props: {
    isOnExpandedLayout: {
      type: Boolean,
      required: true,
    },
  },

  data() {
    return {
      searchTerm: '',
      showSearchBox: false,
    };
  },

  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
    searchUrl() {
      return frontendURL(`accounts/${this.accountId}/search`);
    },
  },
};
</script>

<style lang="scss" scoped>
.search-wrap {
  position: relative;
}

.search {
  display: flex;
  padding: 0;
  border-bottom: 1px solid transparent;
  padding: var(--space-one) var(--space-normal) var(--space-smaller)
    var(--space-normal);

  &:hover {
    .search--icon,
    .search--label {
      color: var(--w-500);
    }
  }
}

.search--link {
  display: inline-flex;
  align-items: center;
  flex: 1;
  background: var(--s-25);
  padding: var(--space-smaller);
  height: var(--space-medium);
  border-radius: var(--border-radius-normal);
  margin-right: var(--space-smaller);
}

.search--label {
  color: var(--color-body);
  margin-bottom: 0;
}

.search--input {
  align-items: center;
  border: 0;
  color: var(--color-body);
  cursor: pointer;
  width: 100%;
  display: flex;
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-normal);
  text-align: left;
  line-height: var(--font-size-large);
}

.search--icon {
  color: var(--s-600);
  margin: 0 var(--space-smaller);
}

.icon {
  display: flex;
}

input::placeholder {
  color: var(--color-body);
  font-size: var(--font-size-small);
}

.results-wrap {
  position: absolute;
  z-index: 9999;
  box-shadow: var(--shadow-large);
  background: white;
  width: 100%;
  max-height: 70vh;
  overflow: auto;
}

.show-results {
  list-style-type: none;
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-normal);
}

.result-view {
  display: flex;
  justify-content: space-between;
}

.result {
  padding: var(--space-smaller) var(--space-smaller) var(--space-smaller)
    var(--space-normal);
  color: var(--s-700);
  font-size: var(--font-size-medium);
  font-weight: var(--font-weight-bold);

  .message-counter {
    color: var(--s-500);
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-bold);
  }
}

.search--activity-message {
  padding: var(--space-small) var(--space-normal) var(--space-small)
    var(--space-zero);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  color: var(--s-500);
}

.search--activity-no-message {
  display: flex;
  justify-content: center;
  padding: var(--space-one) var(--space-zero) var(--space-two) var(--space-zero);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  color: var(--s-500);
}
</style>
