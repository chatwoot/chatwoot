<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue';
import WootSnackbar from './Snackbar.vue';
import { emitter } from 'shared/helpers/mitt';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  duration: {
    type: Number,
    default: 2500,
  },
});

const { t } = useI18n();

const snackMessages = ref([]);
const snackbarContainer = ref(null);

const showPopover = () => {
  try {
    const el = snackbarContainer.value;
    if (el?.matches(':popover-open')) {
      el.hidePopover();
    }
    el?.showPopover();
  } catch (e) {
    // ignore
  }
};

const onNewToastMessage = ({ message: originalMessage, action }) => {
  const message = action?.usei18n ? t(originalMessage) : originalMessage;
  const duration = action?.duration || props.duration;
  const key = action?.key || Date.now();

  snackMessages.value.push({
    key,
    message,
    action,
  });

  nextTick(showPopover);

  if (!action?.persistent) {
    setTimeout(() => {
      snackMessages.value = snackMessages.value.filter(m => m.key !== key);
    }, duration);
  }
};

const onDismissToastMessage = ({ key }) => {
  snackMessages.value = snackMessages.value.filter(m => m.key !== key);
};

onMounted(() => {
  emitter.on('newToastMessage', onNewToastMessage);
  emitter.on('dismissToastMessage', onDismissToastMessage);
});

onUnmounted(() => {
  emitter.off('newToastMessage', onNewToastMessage);
  emitter.off('dismissToastMessage', onDismissToastMessage);
});
</script>

<template>
  <div
    ref="snackbarContainer"
    popover="manual"
    class="fixed top-4 left-1/2 -translate-x-1/2 max-w-[25rem] w-[calc(100%-2rem)] text-center bg-transparent border-0 p-0 m-0 outline-none overflow-visible"
  >
    <transition-group name="toast-fade" tag="div">
      <WootSnackbar
        v-for="snackMessage in snackMessages"
        :key="snackMessage.key"
        :message="snackMessage.message"
        :action="snackMessage.action"
      />
    </transition-group>
  </div>
</template>
