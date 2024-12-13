<script setup>
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from '../avatar/Avatar.vue';

const props = defineProps({
  message: {
    type: Object,
    required: true,
  },
});

const useCopilotResponse = () => {
  emitter.emit(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, props.message?.content);
};
</script>

<template>
  <div class="flex flex-row gap-2">
    <Avatar
      name="Captain Copilot"
      icon-name="i-woot-captain"
      :size="24"
      rounded-full
    />
    <div class="flex flex-col gap-1 text-n-slate-12">
      <div class="font-medium">{{ $t('CAPTAIN.NAME') }}</div>
      <div class="break-words">
        {{ message.content }}
      </div>
      <div class="flex flex-row mt-1">
        <Button
          :label="$t('CAPTAIN.COPILOT.USE')"
          faded
          sm
          slate
          @click="useCopilotResponse"
        />
      </div>
    </div>
  </div>
</template>
