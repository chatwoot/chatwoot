<!-- eslint-disable vue/attribute-hyphenation -->
<template>
  <ninja-keys
    ref="ninjakeys"
    :no-auto-load-md-icons="true"
    hideBreadcrumbs
    :placeholder="placeholder"
  />
</template>

<script>
import 'ninja-keys';
import conversationHotKeysMixin from './conversationHotKeys';
import goToCommandHotKeys from './goToCommandHotKeys';
import agentMixin from 'dashboard/mixins/agentMixin';
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';
import conversationTeamMixin from 'dashboard/mixins/conversation/teamMixin';
import adminMixin from 'dashboard/mixins/isAdmin';

export default {
  mixins: [
    adminMixin,
    agentMixin,
    conversationHotKeysMixin,
    conversationLabelMixin,
    conversationTeamMixin,
    goToCommandHotKeys,
  ],

  data() {
    return {
      placeholder: this.$t('COMMAND_BAR.SEARCH_PLACEHOLDER'),
    };
  },
  computed: {
    accountId() {
      return this.$store.getters.getCurrentAccountId;
    },
    routeName() {
      return this.$route.name;
    },
    hotKeys() {
      return [...this.conversationHotKeys, ...this.goToCommandHotKeys];
    },
  },
  watch: {
    routeName() {
      this.setCommandbarData();
    },
  },
  mounted() {
    this.setCommandbarData();
  },
  methods: {
    setCommandbarData() {
      this.$refs.ninjakeys.data = this.hotKeys;
    },
  },
};
</script>

<style>
ninja-keys {
  --ninja-accent-color: var(--w-500);
  --ninja-font-family: 'Inter';
  z-index: 9999;
}
</style>
