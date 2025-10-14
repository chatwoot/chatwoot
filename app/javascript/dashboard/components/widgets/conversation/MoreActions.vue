<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import ResolveAction from '../../buttons/ResolveAction.vue';

// No props needed as we're getting currentChat from the store directly
const store = useStore();

const currentChat = computed(() => store.getters.getSelectedChat);
</script>

<template>
  <div class="relative flex items-center actions--container">
    <ResolveAction
      :conversation-id="currentChat.id"
      :status="currentChat.status"
    />
  </div>
</template>
