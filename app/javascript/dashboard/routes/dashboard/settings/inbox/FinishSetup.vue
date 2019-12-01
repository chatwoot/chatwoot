<template>
  <div class="wizard-body columns content-box small-9">
    <empty-state
      :title="$t('INBOX_MGMT.FINISH.TITLE')"
      :message="message"
      :button-text="$t('INBOX_MGMT.FINISH.BUTTON_TEXT')"
    >
      <div class="medium-12 columns text-center">
        <div class="website--code">
          <woot-code v-if="$route.params.website_token" :script="websiteScript">
          </woot-code>
        </div>
        <router-link
          class="button success nice"
          :to="{
            name: 'inbox_dashboard',
            params: { inboxId: this.$route.params.inbox_id },
          }"
        >
          {{ $t('INBOX_MGMT.FINISH.BUTTON_TEXT') }}
        </router-link>
      </div>
    </empty-state>
  </div>
</template>

<script>
import { createWebsiteWidgetScript } from 'dashboard/helper/scriptGenerator';
import EmptyState from '../../../../components/widgets/EmptyState';

export default {
  components: {
    EmptyState,
  },
  computed: {
    message() {
      if (!this.$route.params.website_token) {
        return this.$t('INBOX_MGMT.FINISH.MESSAGE');
      }
      return this.$t('INBOX_MGMT.FINISH.WEBSITE_SUCCESS');
    },
    websiteScript() {
      return createWebsiteWidgetScript(this.$route.params.website_token);
    },
  },
};
</script>
<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';

.website--code {
  margin: $space-normal auto;
  max-width: 60%;
}
</style>
