<template>
    <div ref="jitsiContainer" class="jitsi-iframe-container"></div>
  </template>
  
  <script>
  export default {
    name: 'JitsiCall',
    props: {
      roomName: { type: String, required: true },
      displayName: { type: String, required: true },
      email: { type: String, default: '' },
      jwt: { type: String, default: '' }
    },
    data() {
      return {
        api: null
      }
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
        return new Promise((resolve) => {
          if (window.JitsiMeetExternalAPI) {
            resolve();
            return;
          }
  
          const script = document.createElement('script');
          script.src = 'https://meet.jit.si/external_api.js';
          script.onload = resolve;
          document.head.appendChild(script);
        });
      },
      initializeJitsi() {
        const options = {
          roomName: this.roomName,
          parentNode: this.$refs.jitsiContainer,
          userInfo: {
            email: this.email,
            displayName: this.displayName
          },
          configOverwrite: {
            prejoinPageEnabled: false,
            startWithAudioMuted: false,
            startWithVideoMuted: false,
            readOnlyName: true
          },
          interfaceConfigOverwrite: {
            SHOW_JITSI_WATERMARK: false,
            SHOW_WATERMARK_FOR_GUESTS: false
          }
        };
  
        if (this.jwt) {
          options.jwt = this.jwt;
        }
  
        this.api = new JitsiMeetExternalAPI('meet.jit.si', options);
  
        // Event listeners
        this.api.on('videoConferenceJoined', () => {
          this.$emit('joined');
          // Force-set display name (optional extra enforcement)
          this.api.executeCommand('displayName', this.displayName);
        });
  
        this.api.on('readyToClose', () => {
          console.log('readyToClose');
          this.$emit('hangup');
        });
      }
    },
    watch: {
      roomName(newVal) {
        if (newVal && this.api) {
          this.api.dispose();
          this.initializeJitsi();
        }
      }
    }
  };
  </script>
  
  <style>
  .jitsi-iframe-container {
    width: 100%;
    height: 100%;
  }
  </style>
  