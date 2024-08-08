<script>
import { mapGetters } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import MacroItem from './MacroItem.vue';

export default {
  components: {
    MacroItem,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  setup() {
    const { accountScopedUrl } = useAccount();

    return {
      accountScopedUrl,
    };
  },
  computed: {
    ...mapGetters({
      macros: ['macros/getMacros'],
      uiFlags: 'macros/getUIFlags',
    }),
  },
  mounted() {
    this.$store.dispatch('macros/get');
  },
};
</script>

<template>
  <div>
    <div
      v-if="!uiFlags.isFetching && !macros.length"
      class="macros_list--empty-state"
    >
      <p class="flex flex-col items-center justify-center h-full">
        {{ $t('MACROS.LIST.404') }}
      </p>
      <router-link :to="accountScopedUrl('settings/macros')">
        <woot-button
          variant="smooth"
          icon="add"
          size="tiny"
          class="macros_add-button"
        >
          {{ $t('MACROS.HEADER_BTN_TXT') }}
        </woot-button>
      </router-link>
    </div>
    <woot-loading-state
      v-if="uiFlags.isFetching"
      :message="$t('MACROS.LOADING')"
    />
    <div v-if="!uiFlags.isFetching && macros.length" class="macros-list">
      <MacroItem
        v-for="macro in macros"
        :key="macro.id"
        :macro="macro"
        :conversation-id="conversationId"
      />
    </div>
  </div>
</template>

<style scoped lang="scss">
.macros-list {
  padding: var(--space-smaller);
}
.macros_list--empty-state {
  padding: var(--space-slab);
  p {
    margin: 0;
  }
}
.macros_add-button {
  margin: var(--space-small) auto 0;
}
</style>
