<script setup>
import JitsiMeet from 'dashboard/components-next/jitsi/JitsiMeet.vue';
import { defineEmits } from 'vue';

const emit = defineEmits(['close']);
const roomName = 'abcd';
const displayName = 'abcd';
const email = 'abcd';
const jwt = 'abcd';

</script>

<template>
  <div v-on-clickaway="() => emit('close')" class="dialog-overlay">
    <div class="dialog-center">
      <JitsiMeet
        :room-name="roomName"
        :display-name="displayName"
        :email="email"
        :jwt="jwt"
        @hangup="emit('close')"
      />
    </div>
  </div>
</template>

<style scoped>
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.3);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.dialog-center {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
  width: 90vw; /* Responsive width */
  max-width: 1200px; /* Maximum width */
  aspect-ratio: 16/9; /* Video aspect ratio */
  padding: 8px; /* Reduced padding */
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Ensure Jitsi iframe fills container */
.dialog-center :deep(iframe) {
  width: 100%;
  height: 100%;
  border-radius: 8px;
  border: none;
}
</style>
