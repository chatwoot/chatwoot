<script setup>
import { computed } from 'vue';
import ShowMore from 'dashboard/components/widgets/ShowMore.vue';
import AgentBotType from './AgentBotType.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  agentBot: {
    type: Object,
    required: true,
  },
  index: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['edit', 'delete']);

const isACSMLTypeBot = computed(() => {
  const { bot_type: botType } = props.agentBot;
  return botType === 'csml';
});
</script>

<template>
  <tr class="space-x-2">
    <td class="py-4 ltr:pl-0 ltr:pr-4 rtl:pl-4 rtl:pr-0">
      <div class="flex items-center break-words font-medium">
        {{ agentBot.name }}
        (<AgentBotType :bot-type="agentBot.bot_type" />)
      </div>
      <div class="text-sm">
        <ShowMore :text="agentBot.description || ''" :limit="120" />
      </div>
    </td>
    <td class="align-middle">
      <div class="flex justify-end gap-1 h-full items-center">
        <Button
          v-if="isACSMLTypeBot"
          v-tooltip.top="$t('AGENT_BOTS.EDIT.BUTTON_TEXT')"
          icon="i-lucide-pen"
          slate
          xs
          faded
          @click="emit('edit', agentBot)"
        />
        <Button
          v-tooltip.top="$t('AGENT_BOTS.DELETE.BUTTON_TEXT')"
          icon="i-lucide-trash-2"
          xs
          ruby
          faded
          @click="emit('delete', agentBot, index)"
        />
      </div>
    </td>
  </tr>
</template>
