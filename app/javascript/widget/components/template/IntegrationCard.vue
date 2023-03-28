<template>
  <div>
    <button
      class="button join-call-button"
      color-scheme="secondary"
      :is-loading="isLoading"
      :style="{
        background: widgetColor,
        borderColor: widgetColor,
        color: textColor,
      }"
      @click="joinTheCall"
    >
      <fluent-icon icon="video-add" class="mr-2" />
      {{ $t('INTEGRATIONS.DYTE.CLICK_HERE_TO_JOIN') }}
    </button>
    <div v-if="dyteAuthToken" class="video-call--container">
      <iframe
        :src="meetingLink"
        allow="camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;"
      />
      <button
        class="button small join-call-button leave-room-button"
        @click="leaveTheRoom"
      >
        {{ $t('INTEGRATIONS.DYTE.LEAVE_THE_ROOM') }}
      </button>
    </div>
  </div>
</template>
<script>
import IntegrationAPIClient from 'widget/api/integration';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { buildDyteURL } from 'shared/helpers/IntegrationHelper';
import { getContrastingTextColor } from '@chatwoot/utils';
import { mapGetters } from 'vuex';

export default {
  components: {
    FluentIcon,
  },
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
    ...mapGetters({ widgetColor: 'appConfig/getWidgetColor' }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    meetingLink() {
      return buildDyteURL(this.meetingData.room_name, this.dyteAuthToken);
    },
  },
  methods: {
    async joinTheCall() {
      this.isLoading = true;
      try {
        const {
          data: { authResponse: { authToken = '' } = {} } = {},
        } = await IntegrationAPIClient.addParticipantToDyteMeeting(
          this.messageId
        );
        this.dyteAuthToken = authToken;
      } catch (error) {
        // Ignore Error for now
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
<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';

.video-call--container {
  position: fixed;
  top: 72px;
  left: 0;
  width: 100%;
  height: 100%;

  z-index: 100;

  iframe {
    width: 100%;
    height: calc(100% - 72px);

    border: 0;
  }
}

.join-call-button {
  margin: $space-small 0;
  border-radius: 4px;
  display: flex;
  align-items: center;
}

.leave-room-button {
  position: absolute;
  top: 0;
  right: $space-small;
}
</style>
