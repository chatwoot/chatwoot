<script>
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
        const domain = 'meet.jit.si';
        script.src = `https://${domain}/external_api.js`;
        script.onload = resolve;
        document.head.appendChild(script);
      });
    },
    initializeJitsi() {
      const options = {
        roomName: this.roomId,
        parentNode: this.$refs.jitsiContainer,
        userInfo: {
          email: this.email,
          displayName: this.displayName,
        },
        configOverwrite: {
          prejoinPageEnabled: false,
          startWithAudioMuted: false,
          startWithVideoMuted: false,
          readOnlyName: true,
        },
        interfaceConfigOverwrite: {
          SHOW_JITSI_WATERMARK: false,
          SHOW_WATERMARK_FOR_GUESTS: false,
          TOOLBAR_BUTTONS: [
            'microphone',
            'camera',
            'hangup',
            'chat',
            'customFloatingToggle', // Custom button
          ],
        },
      };

      if (this.jwt != '') {
        options.jwt = this.jwt;
        console.log('jwt', this.jwt);
      }

      const domain = 'meet.jit.si';
      this.api = new JitsiMeetExternalAPI(domain, options);

      function toggleFloating() {
        const jitsiContainer = document.getElementById('jitsi-container');
        const isFloating = jitsiContainer.classList.toggle('floating');

        if (isFloating) {
          jitsiContainer.style.position = 'fixed';
          jitsiContainer.style.bottom = '20px';
          jitsiContainer.style.right = '20px';
          jitsiContainer.style.width = '300px';
          jitsiContainer.style.height = '200px';
          jitsiContainer.style.zIndex = '9999';
          jitsiContainer.style.boxShadow = '0 0 10px rgba(0,0,0,0.3)';
        } else {
          jitsiContainer.style = '';
        }
      }

      // Register custom button
      this.api.addButton({
        id: 'customFloatingToggle',
        title: 'Minimize',
        icon: 'https://img.icons8.com/ios-glyphs/30/minimize-window.png', // use your icon URL
        onClick: () => toggleFloating(),
      });

      // Event listeners
      this.api.on('videoConferenceJoined', () => {
        console.log('videoConferenceJoined event fired');
        this.$emit('joined');
        this.minimizeButton.style.display = 'flex';
        // Force-set display name (optional extra enforcement)
        this.api.executeCommand('displayName', this.displayName);
      });

      // Add more debug listeners
      this.api.on('videoConferenceLeft', () => {
        console.log('videoConferenceLeft event fired');
      });

      this.api.on('participantLeft', () => {
        console.log('participantLeft event fired');
      });

      this.api.on('readyToClose', () => {
        console.log('readyToClose event fired');
        this.$emit('hangup');
      });

      // Add error event listener
      this.api.on('errorOccurred', error => {
        console.error('Jitsi error: event fired', error);
      });

      document
        .getElementById('minimizeButton')
        .addEventListener('click', () => {
          toggleFloating();
        });
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
}
</style>

<template>
  <div>
    <div ref="buttonContainer" class="button-container">
      <button ref="minimizeButton" class="minimize-button">Minimize</button>
    </div>
    <div ref="jitsiContainer" class="jitsi-iframe-container"></div>
  </div>
</template>
