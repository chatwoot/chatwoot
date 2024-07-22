<template>
  <div class="relative">
    <div
      class="flex px-4 pb-1 flex-row gap-1 pt-2.5 border-b border-transparent"
    >
      <woot-sidemenu-icon
        size="tiny"
        class="relative top-0 ltr:-ml-1.5 rtl:-mr-1.5"
      />
      <router-link
        :to="searchUrl"
        class="inline-flex items-center flex-1 h-6 gap-1 px-2 py-0 text-left rounded-md search-link rtl:mr-3 rtl:text-right bg-slate-25 dark:bg-slate-800"
      >
        <div class="flex">
          <fluent-icon
            icon="search"
            class="search--icon text-slate-800 dark:text-slate-200"
            size="16"
          />
        </div>
        <p
          class="mb-0 overflow-hidden text-sm search--label whitespace-nowrap text-ellipsis text-slate-800 dark:text-slate-200"
        >
          {{ $t('CONVERSATION.SEARCH_MESSAGES') }}
        </p>
      </router-link>
      <switch-layout
        :is-on-expanded-layout="isOnExpandedLayout"
        @toggle="$emit('toggle-conversation-layout')"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
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
  mixins: [messageFormatterMixin],
  props: {
    isOnExpandedLayout: {
      type: Boolean,
      required: true,
    },
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
.search-link {
  &:hover {
    .search--icon,
    .search--label {
      @apply hover:text-woot-500 dark:hover:text-woot-500;
    }
  }
}
</style>
