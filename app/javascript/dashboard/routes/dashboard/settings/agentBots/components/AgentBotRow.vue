<script setup>
import ShowMore from 'dashboard/components/widgets/ShowMore.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
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
</script>

<template>
  <tr class="space-x-2">
    <td class="py-4 ltr:pl-0 ltr:pr-4 rtl:pl-4 rtl:pr-0">
      <div class="flex items-center break-words font-medium">
        {{ agentBot.name }}
      </div>
      <div class="text-sm">
        <ShowMore :text="agentBot.description || ''" :limit="120" />
      </div>
    </td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">{{ agentBot.description }}</td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">
      {{ agentBot.bot_config?.webhook_url }}
    </td>
    <td class="align-middle">
      <div class="flex justify-end gap-1 h-full items-center">
        <Button
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
