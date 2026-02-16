<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  chat: {
    type: Object,
    required: true,
  },
  variant: {
    type: String,
    default: 'ghost',
  },
  size: {
    type: String,
    default: 'sm',
  },
});

const store = useStore();
const { t } = useI18n();

const alooAssistant = computed(() => props.chat.aloo_assistant);
const hasAlooAssistant = computed(
  () => alooAssistant.value?.id && alooAssistant.value?.active
);
const assignedAgent = computed(() => props.chat.meta?.assignee);
const isAlooAIHandling = computed(() => {
  // AI is handling if: inbox has active Aloo assistant AND no human assignee
  return alooAssistant.value?.active && !assignedAgent.value;
});

// Toggle button state
const buttonLabel = computed(() =>
  isAlooAIHandling.value
    ? t('CONVERSATION.ALOO.TAKE_OVER_BUTTON')
    : t('CONVERSATION.ALOO.ASSIGN_TO_AI_BUTTON')
);

const buttonIcon = computed(() =>
  isAlooAIHandling.value ? 'i-lucide-user' : 'i-lucide-bot'
);

// Actions
const assignToAI = async () => {
  try {
    await store.dispatch('assignAgent', {
      conversationId: props.chat.id,
      agentId: null,
    });
    useAlert(t('CONVERSATION.ALOO.ASSIGN_TO_AI_SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION.ALOO.ASSIGN_TO_AI_ERROR'));
  }
};

const takeOver = async () => {
  try {
    const currentUser = store.getters.getCurrentUser;
    // Clear human_assistance_requested on takeover
    if (props.chat.custom_attributes?.human_assistance_requested) {
      await store.dispatch('updateCustomAttributes', {
        conversationId: props.chat.id,
        customAttributes: {
          ...props.chat.custom_attributes,
          human_assistance_requested: false,
        },
      });
    }
    await store.dispatch('assignAgent', {
      conversationId: props.chat.id,
      agentId: currentUser.id,
    });
    useAlert(t('CONVERSATION.ALOO.TAKE_OVER_SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION.ALOO.TAKE_OVER_ERROR'));
  }
};

const handleClick = () => {
  if (isAlooAIHandling.value) {
    takeOver();
  } else {
    assignToAI();
  }
};
</script>

<template>
  <Button
    v-if="hasAlooAssistant"
    :variant="variant"
    :size="size"
    :icon="buttonIcon"
    :label="buttonLabel"
    @click="handleClick"
  />
</template>
