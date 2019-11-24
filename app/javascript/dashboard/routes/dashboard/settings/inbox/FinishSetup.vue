<template>
  <div class="wizard-body columns content-box small-9">
    <empty-state :title="$t('INBOX_MGMT.FINISH.TITLE')" :message="$t('INBOX_MGMT.FINISH.MESSAGE')" :buttonText="$t('INBOX_MGMT.FINISH.BUTTON_TEXT')">
      <div class="medium-12 columns text-center">
        <router-link class="button success nice" :to="{ name: 'inbox_dashboard', params: { inboxId: this.$route.params.inbox_id }}">{{$t('INBOX_MGMT.FINISH.BUTTON_TEXT')}}</router-link>
      </div>
    </empty-state>
  </div>
</template>

<script>
import EmptyState from '../../../../components/widgets/EmptyState';

export default {
  components: {
    EmptyState,
  },
};
</script>
