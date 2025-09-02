<template>
  <div v-if="show" class="fixed top-4 right-4 z-50 max-w-md">
    <div class="bg-amber-50 border-l-4 border-amber-400 p-4 shadow-lg rounded-md">
      <div class="flex items-start">
        <div class="flex-shrink-0">
          <i class="ri-time-line text-amber-400 text-xl"></i>
        </div>
        <div class="ml-3 flex-1">
          <h3 class="text-amber-800 font-medium text-sm">Rate Limit Reached</h3>
          <p class="mt-2 text-amber-700 text-sm leading-relaxed">
            {{ message }}
          </p>
          <div v-if="upgradeAvailable" class="mt-3">
            <button 
              @click="$emit('upgrade-clicked')"
              class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded text-amber-800 bg-amber-100 hover:bg-amber-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-amber-500 transition-colors"
            >
              <i class="ri-arrow-up-line mr-1"></i>
              Upgrade Plan
            </button>
          </div>
          <div v-if="retryAfter" class="mt-2 text-xs text-amber-600">
            <i class="ri-refresh-line mr-1"></i>
            Try again in {{ retryCountdown }} seconds
          </div>
        </div>
        <div class="ml-4 flex-shrink-0">
          <button 
            @click="dismiss"
            class="inline-flex text-amber-400 hover:text-amber-600 focus:outline-none focus:text-amber-600 transition-colors"
          >
            <i class="ri-close-line text-lg"></i>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  },
  message: {
    type: String,
    default: 'You have exceeded the rate limit. Please wait a moment and try again.'
  },
  retryAfter: {
    type: Number,
    default: 60
  },
  upgradeAvailable: {
    type: Boolean,
    default: false
  },
  autoHide: {
    type: Boolean,
    default: true
  },
  hideDelay: {
    type: Number,
    default: 10000 // 10 seconds
  }
});

const emit = defineEmits(['hide', 'upgrade-clicked', 'retry']);

const countdown = ref(props.retryAfter);
let countdownInterval = null;
let hideTimeout = null;

const retryCountdown = computed(() => Math.max(0, countdown.value));

const startCountdown = () => {
  if (countdownInterval) clearInterval(countdownInterval);
  
  countdown.value = props.retryAfter;
  countdownInterval = setInterval(() => {
    countdown.value--;
    if (countdown.value <= 0) {
      clearInterval(countdownInterval);
      emit('retry');
    }
  }, 1000);
};

const startAutoHide = () => {
  if (!props.autoHide) return;
  
  if (hideTimeout) clearTimeout(hideTimeout);
  hideTimeout = setTimeout(() => {
    dismiss();
  }, props.hideDelay);
};

const dismiss = () => {
  cleanup();
  emit('hide');
};

const cleanup = () => {
  if (countdownInterval) {
    clearInterval(countdownInterval);
    countdownInterval = null;
  }
  if (hideTimeout) {
    clearTimeout(hideTimeout);
    hideTimeout = null;
  }
};

onMounted(() => {
  if (props.show) {
    startCountdown();
    startAutoHide();
  }
});

onUnmounted(() => {
  cleanup();
});

// Watch for show prop changes
watch(() => props.show, (newShow) => {
  if (newShow) {
    startCountdown();
    startAutoHide();
  } else {
    cleanup();
  }
});
</script>