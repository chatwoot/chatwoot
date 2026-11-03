<script setup>
// Loaded lazily, so every import from the package stays in this chunk.
import { useTemplateRef } from 'vue';
import { CaptainAvatar } from '@chatwoot/captain-avatar/vue';
import {
  error,
  happy,
  searching,
  sleeping,
  thinking,
  typing,
  working,
} from '@chatwoot/captain-avatar';

defineProps({
  state: { type: String, default: 'idle' },
  size: { type: Number, required: true },
  label: { type: String, required: true },
  entrance: { type: Boolean, default: false },
  paused: { type: Boolean, default: false },
});

const emit = defineEmits(['unsupported', 'poke']);

const STATES = [thinking, searching, working, typing, happy, error, sleeping];

const avatar = useTemplateRef('avatar');
defineExpose({
  enter: () => avatar.value.enter(),
  keyStroke: () => avatar.value.keyStroke(),
});
</script>

<template>
  <CaptainAvatar
    ref="avatar"
    :states="STATES"
    :state="state"
    :size="size"
    :label="label"
    :entrance="entrance"
    :paused="paused"
    @unsupported="emit('unsupported')"
    @poke="emit('poke')"
  />
</template>
