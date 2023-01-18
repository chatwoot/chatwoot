<template>
  <div>
    <woot-button
      size="small"
      variant="smooth"
      color-scheme="secondary"
      icon="video-add"
      class="join-call-button"
      :is-loading="isLoading"
      @click="joinTheCall"
    >
      {{ $t('INTEGRATION_SETTINGS.DYTE.CLICK_HERE_TO_JOIN') }}
    </woot-button>
    <div v-if="dyteAuthToken" class="video-call--container">
      <iframe
        :src="meetingLink"
        allow="camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;"
      />
      <woot-button
        size="small"
        variant="smooth"
        color-scheme="secondary"
        class="join-call-button"
        @click="leaveTheRoom"
      >
        {{ $t('INTEGRATION_SETTINGS.DYTE.LEAVE_THE_ROOM') }}
      </woot-button>
    </div>
  </div>
</template>
<script>
import DyteAPI from 'dashboard/api/integrations/dyte';
import { buildDyteURL } from 'shared/helpers/IntegrationHelper';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  mixins: [alertMixin],
  props: {
    messageId: {
      type: Number,
      required: true,
    },
    meetingData: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return { isLoading: false, dyteAuthToken: '', isSDKMounted: false };
  },
  computed: {
    meetingLink() {
      return buildDyteURL(this.meetingData.room_name, this.dyteAuthToken);
    },
  },
  methods: {
    async joinTheCall() {
      this.isLoading = true;
      try {
        const {
          data: { authResponse: { authToken } = {} } = {},
        } = await DyteAPI.addParticipantToMeeting(this.messageId);
        this.dyteAuthToken = authToken;
      } catch (err) {
        this.showAlert(this.$t('INTEGRATION_SETTINGS.DYTE.JOIN_ERROR'));
      } finally {
        this.isLoading = false;
      }
    },
    leaveTheRoom() {
      this.dyteAuthToken = '';
    },
  },
};
</script>
<style lang="scss">
.join-call-button {
  margin: var(--space-small) 0;
}

.video-call--container {
  position: fixed;
  bottom: 0;
  right: 0;
  width: 100%;
  height: 100%;
  z-index: var(--z-index-high);
  padding: var(--space-smaller);
  background: var(--b-800);

  iframe {
    width: 100%;
    height: 100%;
    border: 0;
  }

  button {
    position: absolute;
    top: var(--space-smaller);
    right: 16rem;
  }
}
</style>
