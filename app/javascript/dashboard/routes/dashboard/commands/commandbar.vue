<!-- eslint-disable vue/attribute-hyphenation -->
<template>
  <ninja-keys
    ref="ninjakeys"
    :no-auto-load-md-icons="true"
    hideBreadcrumbs
    :placeholder="placeholder"
    @selected="setCommandbarData"
    @change="onChange"
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
import { frontendURL } from '../../../helper/URLHelper';

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
    setCommandbarData(e) {
      if (e && e.detail.action.id && e.detail.action.title) {
        const action = e.detail.action;
        if (action.type === 'contact') {
          this.$refs.ninjakeys.close();
          this.$router.push(
            frontendURL(`accounts/${this.accountId}/contacts/${action.key}`)
          );
        } else if (action.type === 'message') {
          this.$refs.ninjakeys.close();
          this.$router.push(
            frontendURL(
              `accounts/${this.accountId}/conversations/${action.key}`
            )
          );
        }
      } else {
        this.$refs.ninjakeys.data = this.hotKeys;
      }
    },
    onChange(ninjaKeyInstance) {
      // console.log(ninjaKeyInstance);
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
