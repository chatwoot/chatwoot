<script>
import DyteAPI from 'dashboard/api/integrations/dyte';
import { buildDyteURL } from 'shared/helpers/IntegrationHelper';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    messageId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return { isLoading: false, dyteAuthToken: '', isSDKMounted: false };
  },
  computed: {
    meetingLink() {
      return buildDyteURL(this.dyteAuthToken);
    },
  },
  methods: {
    async joinTheCall() {
      this.isLoading = true;
      try {
        const { data: { token } = {} } = await DyteAPI.addParticipantToMeeting(
          this.messageId
        );
        this.dyteAuthToken = token;
      } catch (err) {
        useAlert(this.$t('INTEGRATION_SETTINGS.DYTE.JOIN_ERROR'));
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

<template>
  <div>
    <NextButton
      blue
      sm
      icon="i-lucide-video"
      :label="$t('INTEGRATION_SETTINGS.DYTE.CLICK_HERE_TO_JOIN')"
      :is-loading="isLoading"
      @click="joinTheCall"
    />
    <div v-if="dyteAuthToken" class="video-call--container">
      <iframe
        :src="meetingLink"
        allow="camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;"
      />
      <NextButton
        sm
        class="mt-2"
        :label="$t('INTEGRATION_SETTINGS.DYTE.LEAVE_THE_ROOM')"
        @click="leaveTheRoom"
      />
    </div>
  </div>
</template>

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
    right: 10rem;
  }
}
</style>
