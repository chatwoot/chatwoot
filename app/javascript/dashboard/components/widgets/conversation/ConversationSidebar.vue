<script setup>
import ContactPanel from 'dashboard/routes/dashboard/conversation/ContactPanel.vue';

const emit = defineEmits(['toggleContactPanel']);

const toggleContactPanel = () => {
  emit('toggleContactPanel');
};
</script>

<template>
  <div
    class="ltr:border-l rtl:border-r border-n-weak h-full overflow-hidden z-10 w-80 min-w-80 2xl:min-w-96 2xl:w-96 flex flex-col bg-n-background"
  >
    <div class="flex flex-1 overflow-auto">
      <ContactPanel
        :conversation-id="currentChat.id"
        :inbox-id="currentChat.inbox_id"
        :on-toggle="toggleContactPanel"
      />
    </div>
  </div>
</template>
