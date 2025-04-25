<script setup>
import JitsiMeet from 'dashboard/components-next/jitsi/JitsiMeet.vue';
import { defineEmits } from 'vue';

const emit = defineEmits(['close']);


const props = defineProps({
  agentId: {
    type: Number,
    required: true,
  },
  roomId: {
    type: String,
    required: true,
  },
  displayName: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
  },
});   

</script>

<template>
  <div v-on-clickaway="() => emit('close')" class="dialog-overlay">
    <div class="dialog-center">
      <JitsiMeet
        :room-id="roomId"
        :agent-id="agentId"
        :display-name="displayName"
        :email="email"
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
