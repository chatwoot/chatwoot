<script setup>
import MessageList from '../../../ui/MessageList.vue';
</script>

<template>
  <MessageList />
</template>

<style>
/*
 * Runtime Theme Customization
 *
 * Consumers can override bubble colors from outside the Shadow DOM.
 * Set these CSS variables on :root or any ancestor element:
 *
 *   --chatwoot-bubble-agent-bg: RGB values for agent message background
 *   --chatwoot-bubble-agent-text: RGB values for agent message text
 *   --chatwoot-bubble-user-bg: RGB values for user message background
 *   --chatwoot-bubble-user-text: RGB values for user message text
 *   --chatwoot-bubble-private-bg: RGB values for private note background
 *   --chatwoot-bubble-private-text: RGB values for private note text
 *   --chatwoot-bubble-bot-bg: RGB values for bot message background
 *   --chatwoot-bubble-bot-text: RGB values for bot message text
 *
 * Example usage in consumer's CSS:
 *   :root {
 *     --chatwoot-bubble-agent-bg: 59 130 246;
 *     --chatwoot-bubble-user-bg: 243 244 246;
 *   }
 */
:host {
  /* FUNKY TEST COLORS - remove these overrides for production */
  --bubble-agent-bg: var(
    --chatwoot-bubble-agent-bg,
    255 105 180
  ); /* Hot Pink */
  --bubble-agent-text: var(--chatwoot-bubble-agent-text, 255 255 255);
  --bubble-user-bg: var(
    --chatwoot-bubble-user-bg,
    144 238 144
  ); /* Lime Green */
  --bubble-user-text: var(--chatwoot-bubble-user-text, 28 32 36);
  --bubble-private-bg: var(
    --chatwoot-bubble-private-bg,
    255 165 0
  ); /* Orange */
  --bubble-private-text: var(--chatwoot-bubble-private-text, 79 52 34);
  --bubble-bot-bg: var(--chatwoot-bubble-bot-bg, 0 255 255); /* Cyan */
  --bubble-bot-text: var(--chatwoot-bubble-bot-text, 28 32 36);
}

.file-uploads {
  overflow: hidden;
  position: relative;
  text-align: center;
  display: inline-block;
}

.file-uploads.file-uploads-html4 input,
.file-uploads.file-uploads-html5 label {
  /* background fix ie  click */
  background: #fff;
  opacity: 0;
  font-size: 20em;
  z-index: 1;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  position: absolute;
  width: 100%;
  height: 100%;
}

.file-uploads.file-uploads-html5 input,
.file-uploads.file-uploads-html4 label {
  /* background fix ie  click */
  position: absolute;
  background: rgba(255, 255, 255, 0);
  overflow: hidden;
  position: fixed;
  width: 1px;
  height: 1px;
  z-index: -1;
  opacity: 0;
}
</style>
