<script setup>
import { onMounted, ref } from 'vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  notif: { type: Object, required: true },
  displayDuration: { type: Number, required: true },
});

const emit = defineEmits(['close', 'open']);

const progressBar = ref(null);

// The bar shrinks over the user-configured display duration. The Web Animations API keeps
// the duration as data instead of an inline style or a stylesheet per duration.
onMounted(() => {
  progressBar.value?.animate?.(
    [{ transform: 'scaleX(1)' }, { transform: 'scaleX(0)' }],
    { duration: props.displayDuration, easing: 'linear', fill: 'forwards' }
  );
});
</script>

<template>
  <div
    class="relative flex flex-col gap-2 w-[300px] px-3 pt-2.5 pb-3 overflow-hidden rounded-2xl bg-n-solid-1 shadow-lg outline outline-1 outline-n-weak cursor-pointer pointer-events-auto transition-transform duration-200 hover:-translate-y-0.5"
    @click="emit('open', notif)"
  >
    <div class="flex items-center justify-between gap-2">
      <span
        v-if="notif.reason"
        class="flex items-center gap-1 min-w-0 text-xxs font-bold tracking-wide uppercase truncate text-n-iris-11"
      >
        <Icon icon="i-lucide-bell" class="flex-shrink-0 size-2.5" />
        {{ notif.reason }}
      </span>
      <button
        class="flex items-center justify-center flex-shrink-0 ml-auto rounded size-[18px] text-n-slate-10 hover:text-n-slate-12 hover:bg-n-alpha-2"
        @click.stop="emit('close', notif.id)"
      >
        <Icon icon="i-lucide-x" class="size-2.5" />
      </button>
    </div>

    <div class="flex items-center gap-2.5">
      <Avatar
        :src="notif.senderAvatar"
        :name="notif.senderName"
        :size="34"
        rounded-full
      />
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-1.5 mb-0.5">
          <span
            class="max-w-[120px] text-sm font-semibold truncate text-n-slate-12"
          >
            {{ notif.senderName }}
          </span>
          <span
            class="flex-shrink-0 px-1.5 text-xs font-medium rounded-full whitespace-nowrap bg-n-iris-3 text-n-iris-11"
          >
            {{ `#${notif.displayId}` }}
          </span>
          <span
            v-if="notif.inboxName"
            class="min-w-0 text-xs truncate text-n-slate-10 before:content-['·'] before:mr-1"
          >
            {{ notif.inboxName }}
          </span>
        </div>
        <p class="m-0 text-xs leading-snug truncate text-n-slate-11">
          {{ notif.messageContent }}
        </p>
      </div>
    </div>

    <div
      ref="progressBar"
      class="absolute bottom-0 left-0 w-full h-[3px] origin-left bg-n-brand"
    />
  </div>
</template>
