<script setup>
import { computed, onMounted, onErrorCaptured } from 'vue';
import { useMessageContext } from '../provider.js';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import BaseBubble from './Base.vue';

const { contentAttributes, id, content } = useMessageContext();

const items = computed(() => {
  return contentAttributes.value?.items || [];
});

const shouldRenderRichCards = computed(() => {
  // If this component is being called, it means the backend already verified
  // that the feature flag is enabled and created the message as cards.
  // We just need to check if we have items to render.
  return items.value.length > 0;
});

// Detect if this is a QuickReplies message (converted to cards)
const isQuickReplies = computed(() => {
  // QuickReplies converted to cards have specific characteristics:
  // 1. Single card with multiple postback actions
  // 2. No image, no description, just title and many buttons
  if (items.value.length !== 1) return false;

  const card = items.value[0];
  const hasOnlyPostbackActions = card.actions?.every(
    action => action.type === 'postback'
  );
  const hasNoImage = !card.media_url && !card.mediaUrl;
  const hasNoDescription = !card.description;
  const hasManyActions = (card.actions?.length || 0) > 3;

  return hasOnlyPostbackActions && hasNoImage && hasNoDescription && hasManyActions;
});

// Heuristic: detect Messenger Button Template mapped as a single card
// with title-only and 1..3 actions, no image/description
const isMessengerButtonTemplate = card => {
  if (!card) return false;
  const noImage = !card.media_url && !card.mediaUrl;
  const noDescription = !card.description;
  const hasTitle = !!card.title;
  const actions = card.actions || [];
  const hasFewActions = actions.length >= 1 && actions.length <= 3;
  const actionTypesOk = actions.every(
    a => a && (a.type === 'postback' || a.type === 'link')
  );
  return hasTitle && noImage && noDescription && hasFewActions && actionTypesOk;
};

const titleClampClass = card =>
  isMessengerButtonTemplate(card) ? 'line-clamp-6' : 'line-clamp-2';

// HTML escaping function for security
const escapeHtml = text => {
  if (!text) return '';
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
};

// Define development mode flag once in script
const isDev = import.meta.env.MODE !== 'production';

// Metrics tracking function
function trackMetric(name, labels) {
  if (window.analytics) {
    window.analytics.track(name, labels);
  }
}

// Handle image loading success
const handleImageLoad = () => {};

// Handle image loading errors
const handleImageError = event => {
  event.target.style.display = 'none';
  trackMetric('cw_rich_cards_render_total', {
    error: 'true',
    type: 'image_error',
    message_id: id.value,
  });
};

// Handle postback button clicks
const handlePostback = action => {
  // Emit postback event with BUS_EVENTS.RICH_POSTBACK
  emitter.emit(BUS_EVENTS.RICH_POSTBACK, {
    messageId: id.value,
    payload: action.payload,
    text: action.text,
    timestamp: new Date().toISOString(),
  });

  trackMetric('cw_rich_cards_render_total', {
    error: 'false',
    type: 'postback_click',
    message_id: id.value,
  });
};

// Track successful render on mount
onMounted(() => {
  if (shouldRenderRichCards.value) {
    trackMetric('cw_rich_cards_render_total', {
      error: 'false',
      type: 'render_success',
      cards_count: items.value.length,
      message_id: id.value,
    });
  }
});

// Handle component errors
onErrorCaptured(err => {
  if (isDev) {
    // eslint-disable-next-line no-console
    console.error('RichCards error:', err);
  }
  trackMetric('cw_rich_cards_render_total', {
    error: 'true',
    type: 'component_error',
    message_id: id.value,
  });

  // Emit fallback event to parent
  emitter.emit(BUS_EVENTS.RICH_CARDS_FALLBACK, { messageId: id.value });
  return false;
});
</script>

<template>
  <BaseBubble v-if="shouldRenderRichCards" class="rich-cards-bubble">
    <div class="rich-cards-container">
      <div
        v-for="(item, index) in items"
        :key="index"
        class="rich-card border-b border-n-slate-6 last:border-b-0"
        role="group"
        :aria-label="item.title || `Card ${index + 1}`"
      >
        <!-- Card Image -->
        <div v-if="item.media_url || item.mediaUrl" class="card-image">
          <img
            :src="item.media_url || item.mediaUrl"
            :alt="escapeHtml(item.title || 'Card image')"
            loading="lazy"
            decoding="async"
            class="w-full h-48 object-cover"
            @error="handleImageError"
            @load="handleImageLoad(item.media_url || item.mediaUrl)"
          />
        </div>

        <!-- Card Content -->
        <div class="card-content p-4">
          <h3
            v-if="item.title"
            class="card-title font-semibold text-base mb-2"
            :class="[titleClampClass(item)]"
          >
            {{ item.title }}
          </h3>
          <p
            v-else-if="item.body"
            class="card-body text-sm text-n-slate-12 mb-3 whitespace-pre-line break-words"
          >
            {{ item.body }}
          </p>
          <p
            v-if="item.description"
            class="card-description text-sm text-n-slate-11 mb-3 line-clamp-3"
          >
            {{ item.description }}
          </p>

          <!-- Action Buttons -->
          <div
            v-if="item.actions && item.actions.length"
            class="card-actions"
            :class="[
              isQuickReplies ? 'quick-replies-scroll' : 'flex flex-col gap-2',
            ]"
          >
            <template
              v-for="(action, actionIndex) in item.actions"
              :key="actionIndex"
            >
              <!-- Link Button -->
              <a
                v-if="action.type === 'link'"
                :href="action.uri"
                target="_blank"
                rel="noopener noreferrer"
                class="card-button card-button--link border border-n-slate-6 rounded-lg px-3 py-2 text-center bg-n-slate-1 hover:bg-n-slate-2 transition-colors text-sm font-medium text-n-slate-12 inline-flex items-center justify-center"
              >
                {{ action.text }}
                <svg
                  class="ml-1 w-3 h-3"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                  />
                </svg>
              </a>

              <!-- Postback Button -->
              <button
                v-else-if="action.type === 'postback'"
                class="card-button card-button--postback border border-n-slate-6 rounded-lg px-3 py-2 text-center bg-n-slate-1 hover:bg-n-slate-2 transition-colors text-sm font-medium text-n-slate-12 w-full"
                @click="handlePostback(action)"
              >
                {{ action.text }}
              </button>
            </template>
          </div>
        </div>
      </div>
    </div>
  </BaseBubble>

  <!-- Fallback for when rich cards can't be rendered -->
  <BaseBubble v-else class="p-4">
    <div class="rich-cards-fallback">
      <p class="text-sm text-n-slate-11 mb-2">
        {{ $t('CONVERSATION.RICH_MESSAGE.RICH_MESSAGE_FALLBACK_TITLE') }}
      </p>
      <div class="text-sm">
        {{
          content.value ||
          contentAttributes.value?.fallback_text ||
          'Rich message content'
        }}
      </div>

      <!-- Debug info (development only) -->
      <details v-if="isDev" class="mt-2 text-xs text-n-slate-10">
        <summary>{{ $t('CONVERSATION.RICH_MESSAGE.DEBUG_INFO') }}</summary>
        <pre class="mt-1 p-2 bg-n-slate-2 rounded text-xs overflow-auto">{{
          JSON.stringify(
            {
              messageId: id.value,
              hasItems: !!contentAttributes.value?.items,
              itemsLength: contentAttributes.value?.items?.length || 0,
              contentAttributes: contentAttributes.value,
            },
            null,
            2
          )
        }}</pre>
      </details>
    </div>
  </BaseBubble>
</template>

<style scoped>
.rich-cards-bubble {
  @apply px-4 py-3;
}

.rich-cards-container {
  @apply max-w-sm;
}

.card-title {
  word-break: break-word;
}

.card-description {
  word-break: break-word;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-6 {
  display: -webkit-box;
  -webkit-line-clamp: 6;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* QuickReplies horizontal scroll styles */
.quick-replies-scroll {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding-bottom: 4px;
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 #f1f5f9;
  -webkit-overflow-scrolling: touch;
  position: relative;
}

.quick-replies-scroll::-webkit-scrollbar {
  height: 4px;
}

.quick-replies-scroll::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 2px;
}

.quick-replies-scroll::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 2px;
}

.quick-replies-scroll::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

/* QuickReplies buttons styling - consistent with WhatsAppInteractive */
.quick-replies-scroll .card-button {
  flex-shrink: 0;
  white-space: nowrap;
  min-width: fit-content;
  max-width: 150px;
  /* Use same style as WhatsAppInteractive */
  border: 1px solid #cbd5e1;
  border-radius: 0.5rem;
  padding: 0.5rem 0.75rem;
  text-align: center;
  background-color: #f8fafc;
  color: #0f172a;
  font-size: 0.875rem;
  font-weight: 500;
  transition: all 0.2s ease;
}

.quick-replies-scroll .card-button:hover {
  background-color: #f1f5f9;
  transform: translateY(-1px);
}

/* Hover effect for normal cards too */
.card-actions:not(.quick-replies-scroll) .card-button:hover {
  transform: translateY(-1px);
}

.quick-replies-scroll .card-button:active {
  transform: translateY(0);
}

/* Normal cards keep flex-wrap for vertical stacking */
.card-actions:not(.quick-replies-scroll) {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

/* Ensure buttons in normal cards take full width */
.card-actions:not(.quick-replies-scroll) .card-button {
  width: 100%;
}

/* Add subtle gradient fade at edges to indicate scrollability */
.quick-replies-scroll::before,
.quick-replies-scroll::after {
  content: '';
  position: absolute;
  top: 0;
  bottom: 0;
  width: 12px;
  pointer-events: none;
  z-index: 1;
}

.quick-replies-scroll::before {
  left: 0;
  background: linear-gradient(to right, rgba(255, 255, 255, 0.9), transparent);
}

.quick-replies-scroll::after {
  right: 0;
  background: linear-gradient(to left, rgba(255, 255, 255, 0.9), transparent);
}
</style>
