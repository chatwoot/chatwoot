<script setup>
import JitsiMeet from 'dashboard/components-next/jitsi/JitsiMeet.vue';
import { ref, onMounted, onBeforeUnmount } from 'vue';

const emit = defineEmits(['close']);
const isFloating = ref(false);
const floatingDialog = ref(null);
const position = ref({ x: null, y: null });
const isDragging = ref(false);
const dragOffset = ref({ x: 0, y: 0 });

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
  jwt: {
    type: String,
    required: true,
  },
});   

const handleHangup = () => {
  emit('close');
}

const handleCallLeft = () => {
  emit('left');
}

const handleToggleFloating = () => {
  isFloating.value = !isFloating.value;
  // Reset position when toggling back to full screen mode
  if (!isFloating.value) {
    position.value = { x: null, y: null };
  }
};

const startDrag = (event) => {
  if (!isFloating.value) return;
  
  isDragging.value = true;
  const rect = floatingDialog.value.getBoundingClientRect();
  
  dragOffset.value = {
    x: event.clientX - rect.left,
    y: event.clientY - rect.top
  };
  
  event.preventDefault();
};

const onDrag = (event) => {
  if (!isDragging.value) return;
  
  position.value = {
    x: event.clientX - dragOffset.value.x,
    y: event.clientY - dragOffset.value.y
  };
  
  // Keep dialog within viewport bounds
  const rect = floatingDialog.value.getBoundingClientRect();
  if (position.value.x < 0) position.value.x = 0;
  if (position.value.y < 0) position.value.y = 0;
  if (position.value.x + rect.width > window.innerWidth) {
    position.value.x = window.innerWidth - rect.width;
  }
  if (position.value.y + rect.height > window.innerHeight) {
    position.value.y = window.innerHeight - rect.height;
  }
};

const endDrag = () => {
  isDragging.value = false;
};

onMounted(() => {
  document.addEventListener('mousemove', onDrag);
  document.addEventListener('mouseup', endDrag);
  document.addEventListener('touchmove', event => {
    if (isDragging.value) {
      const touch = event.touches[0];
      onDrag({ clientX: touch.clientX, clientY: touch.clientY });
      event.preventDefault();
    }
  }, { passive: false });
  document.addEventListener('touchend', endDrag);
});

onBeforeUnmount(() => {
  document.removeEventListener('mousemove', onDrag);
  document.removeEventListener('mouseup', endDrag);
  document.removeEventListener('touchmove', event => {}, { passive: false });
  document.removeEventListener('touchend', endDrag);
});

</script>

<template>
  <div 
    ref="floatingDialog"
    :class="{
      'dialog-overlay': !isFloating,
      'floating-dialog': isFloating
    }"
    v-on-clickaway="() => !isFloating && emit('close')"
    :style="isFloating && position.x !== null ? 
      { left: `${position.x}px`, top: `${position.y}px`, right: 'auto', bottom: 'auto' } : {}"
  >
    <div 
      v-if="isFloating" 
      class="drag-handle"
      @mousedown="startDrag"
      @touchstart.prevent="startDrag"
    ></div>
    <div :class="{
      'dialog-center': !isFloating,
      'floating-container': isFloating
    }">
      <JitsiMeet
        :room-id="roomId"
        :agent-id="agentId"
        :display-name="displayName"
        :email="email"
        :jwt="jwt"
        @hangup="handleHangup"
        @toggle-floating="handleToggleFloating"
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

.floating-dialog {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 9999;
  transition: none; /* Disable transition for smooth dragging */
}

.floating-container {
  width: 420px; /* Increased from 360px */
  height: 236px; /* Increased while maintaining 16:9 aspect ratio */
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
  overflow: hidden;
}

.drag-handle {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 32px;
  background: rgba(0, 0, 0, 0.15);
  z-index: 101;
  cursor: move;
  border-top-left-radius: 8px;
  border-top-right-radius: 8px;
}

/* Ensure Jitsi iframe fills container */
:deep(iframe) {
  width: 100%;
  height: 100%;
  border-radius: 8px;
  border: none;
}
</style>
