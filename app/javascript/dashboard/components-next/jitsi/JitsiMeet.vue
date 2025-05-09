<script>
import { JITSI_CONFIG } from '../../../shared/constants/jitsi';

export default {
  name: 'JitsiCall',
  props: {
    roomId: {
      type: String,
      required: true,
    },
    agentId: {
      type: Number,
      required: true,
    },
    displayName: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      default: '',
    },
    jwt: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      api: null,
    };
  },
  mounted() {
    this.loadJitsiScript().then(() => {
      this.initializeJitsi();
    });
  },
  beforeUnmount() {
    if (this.api) {
      this.api.dispose();
    }
  },
  methods: {
    loadJitsiScript() {
      return new Promise(resolve => {
        if (window.JitsiMeetExternalAPI) {
          resolve();
          return;
        }

        const script = document.createElement('script');
        script.src = `https://${JITSI_CONFIG.domain}/external_api.js`;
        script.onload = resolve;
        document.head.appendChild(script);
      });
    },
    initializeJitsi() {
      const options = {
        roomName: this.roomId,
        parentNode: this.$refs.jitsiContainer,
        jwt: this.jwt,
        userInfo: {
          email: this.email,
          displayName: this.displayName,
        },
        configOverwrite: {
          apiLogLevels: ['error'],
          prejoinPageEnabled: false,
          startWithAudioMuted: false,
          startWithVideoMuted: false,
          readOnlyName: true,
        },
        interfaceConfigOverwrite: {
          SHOW_JITSI_WATERMARK: false,
          SHOW_WATERMARK_FOR_GUESTS: false,
          // TOOLBAR_BUTTONS: ['microphone', 'camera', 'hangup', 'chat'],
        },
      };

      if (this.jwt != '') {
        options.jwt = this.jwt;
      }

      this.api = new JitsiMeetExternalAPI(JITSI_CONFIG.domain, options);

      this.api.on('videoConferenceJoined', () => {
        this.$emit('joined');
        this.api.executeCommand('displayName', this.displayName);
      });

      this.api.on('videoConferenceLeft', () => {
        this.$emit('left');
      });

      this.api.on('participantLeft', () => {});

      this.api.on('readyToClose', () => {
        this.$emit('hangup');
      });

      // Add error event listener
      this.api.on('errorOccurred', error => {
        console.error('Jitsi error:', error);
      });
    },
    toggleFloating() {
      this.$emit('toggle-floating');
    },
  },
  watch: {
    roomName(newVal) {
      if (newVal && this.api) {
        this.api.dispose();
        this.initializeJitsi();
      }
    },
  },
};
</script>

<style>
.jitsi-iframe-container {
  width: 100%;
  height: 100%;
  position: relative;
}

.button-container {
  position: absolute;
  top: 16px;
  left: 16px;
  z-index: 100;
}

.minimize-button {
  width: 32px;
  height: 32px;
  padding: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  background: rgba(0, 0, 0, 0.4);
  border: none;
  cursor: pointer;
  transition: background 0.2s ease;
}

.minimize-button:hover {
  background: rgba(0, 0, 0, 0.6);
}

.minimize-button img {
  width: 16px;
  height: 16px;
  filter: invert(1);
}
</style>

<template>
  <div ref="jitsiContainer" class="jitsi-iframe-container">
    <div ref="buttonContainer" class="button-container">
      <button
        ref="minimizeButton"
        class="minimize-button"
        @click="toggleFloating"
      >
        <img
          src="https://img.icons8.com/ios-glyphs/30/minimize-window.png"
          alt="Minimize"
        />
      </button>
    </div>
  </div>
</template>
