<script setup>
import { computed, onMounted, onUnmounted, onErrorCaptured, watch } from 'vue';
import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';
import MessageFormatter from 'shared/helpers/MessageFormatter.js';

const { contentAttributes, content, id } = useMessageContext();

// Define development mode flag
const isDev = import.meta.env.MODE !== 'production';

const interactivePayload = computed(() => {
  // Check for interactive payload first
  if (
    contentAttributes.value?.whatsapp_interactive_payload ||
    contentAttributes.value?.interactive
  ) {
    return (
      contentAttributes.value?.whatsapp_interactive_payload ||
      contentAttributes.value?.interactive ||
      {}
    );
  }

  // Check for template payload (templates with buttons/images)
  if (contentAttributes.value?.whatsapp_template_payload) {
    return normalizeTemplateToInteractive(
      contentAttributes.value?.whatsapp_template_payload
    );
  }

  return {};
});

// Normalize template payload to interactive format for unified rendering
const normalizeTemplateToInteractive = template => {
  if (!template) return {};

  const result = {
    type: 'button',
    body: {},
    header: {},
    footer: {},
    action: { buttons: [] },
  };

  // Extract components from template
  const components = template.components || [];

  components.forEach(component => {
    const compType = (component.type || '').toUpperCase();

    switch (compType) {
      case 'HEADER':
        if (component.parameters?.[0]?.type === 'image') {
          result.header = {
            type: 'image',
            image: { link: component.parameters[0].image?.link || '' },
          };
        } else if (component.parameters?.[0]?.type === 'text') {
          result.header = {
            type: 'text',
            text: component.parameters[0].text || '',
          };
        }
        break;

      case 'BODY':
        // Body text comes from the template text or parameters
        if (component.parameters?.length > 0) {
          const bodyParts = component.parameters.map(p => p.text || '');
          result.body.text = bodyParts.join(' ');
        }
        break;

      case 'FOOTER':
        if (component.parameters?.[0]?.text) {
          result.footer.text = component.parameters[0].text;
        }
        break;

      case 'BUTTON':
        if (component.parameters?.[0]) {
          result.action.buttons.push({
            type: 'reply',
            reply: {
              title:
                component.parameters[0].text ||
                component.parameters[0].coupon_code ||
                'Button',
            },
          });
        }
        break;
    }
  });

  // If no body text was extracted, try to use template name
  if (!result.body.text && template.name) {
    result.body.text = `Template: ${template.name}`;
  }

  return result;
};

const interactiveType = computed(() => {
  return interactivePayload.value?.type || 'unknown';
});

const bodyText = computed(() => {
  const text = interactivePayload.value?.body?.text || content.value || '';
  return new MessageFormatter(text).formattedMessage;
});

const headerImage = computed(() => {
  const header = interactivePayload.value?.header;
  if (header?.type === 'image' && header?.image?.link) {
    return header.image.link;
  }
  return null;
});

const footerText = computed(() => {
  const text = interactivePayload.value?.footer?.text || '';
  return text ? new MessageFormatter(text).formattedMessage : '';
});

const buttons = computed(() => {
  return interactivePayload.value?.action?.buttons || [];
});

const listSections = computed(() => {
  return interactivePayload.value?.action?.sections || [];
});

const listButtonText = computed(() => {
  const text = interactivePayload.value?.action?.button || 'Ver opções';
  return new MessageFormatter(text).formattedMessage;
});

const isButtonTemplate = computed(() => {
  return interactiveType.value === 'button';
});

const isListTemplate = computed(() => {
  return interactiveType.value === 'list';
});

const shouldRenderInteractive = computed(() => {
  const shouldRender =
    interactivePayload.value &&
    Object.keys(interactivePayload.value).length > 0 &&
    (isButtonTemplate.value || isListTemplate.value);

  return shouldRender;
});

// Format button text for display
const formatButtonTitle = button => {
  const text = button?.reply?.title || button?.title || 'Botão';
  return new MessageFormatter(text).formattedMessage;
};

// Format list row for display
const formatListRow = row => {
  let text = row.title || '';
  if (row.description) {
    text += ` - ${row.description}`;
  }
  return new MessageFormatter(text).formattedMessage;
};

// Format section title for display
const formatSectionTitle = section => {
  const text = section.title || '';
  return new MessageFormatter(text).formattedMessage;
};

// Debug lifecycle hooks
onMounted(() => {});

// Watch for changes in contentAttributes
watch(
  contentAttributes,
  (newVal, oldVal) => {
    // Check if interactive data was lost
    const hadInteractive = !!(
      oldVal?.whatsapp_interactive_payload || oldVal?.interactive
    );
    const hasInteractive = !!(
      newVal?.whatsapp_interactive_payload || newVal?.interactive
    );

    if (hadInteractive && !hasInteractive) {
      // Interactive data was lost
    }
  },
  { deep: true }
);

// Watch for changes in shouldRenderInteractive
watch(shouldRenderInteractive, () => {
  // Watch logic removed for production
});

// Handle component unmount
onUnmounted(() => {});

// Handle component errors
onErrorCaptured(() => {
  return false;
});
</script>

<template>
  <BaseBubble
    v-if="shouldRenderInteractive"
    class="whatsapp-interactive-bubble"
  >
    <!-- Header Image -->
    <div v-if="headerImage" class="whatsapp-header mb-3">
      <img
        :src="headerImage"
        :alt="$t('CONVERSATION.WHATSAPP_INTERACTIVE_IMAGE')"
        class="w-full rounded-lg max-h-48 object-cover"
        @error="$event.target.style.display = 'none'"
      />
    </div>

    <!-- Body Text -->
    <div v-if="bodyText" class="whatsapp-body mb-3">
      <div v-dompurify-html="bodyText" class="prose prose-bubble text-sm" />
    </div>

    <!-- Button Template -->
    <div v-if="isButtonTemplate && buttons.length > 0" class="whatsapp-buttons">
      <div class="flex flex-col gap-2">
        <div
          v-for="(button, index) in buttons"
          :key="index"
          class="whatsapp-button"
        >
          <div
            class="border border-n-slate-6 rounded-lg px-3 py-2 text-center bg-n-slate-1 hover:bg-n-slate-2 transition-colors"
          >
            <span
              v-dompurify-html="formatButtonTitle(button)"
              class="text-sm font-medium text-n-slate-12"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- List Template -->
    <div v-if="isListTemplate && listSections.length > 0" class="whatsapp-list">
      <!-- List Button -->
      <div class="whatsapp-list-button mb-3">
        <div
          class="border border-n-slate-6 rounded-lg px-3 py-2 text-center bg-n-slate-1 hover:bg-n-slate-2 transition-colors"
        >
          <span
            v-dompurify-html="listButtonText"
            class="text-sm font-medium text-n-slate-12"
          />
        </div>
      </div>

      <!-- List Options Preview -->
      <div class="whatsapp-list-options">
        <div
          v-for="(section, sectionIndex) in listSections"
          :key="sectionIndex"
          class="mb-3 last:mb-0"
        >
          <div
            v-if="section.title"
            v-dompurify-html="formatSectionTitle(section)"
            class="text-xs font-semibold text-n-slate-11 mb-2 uppercase tracking-wide"
          />
          <div class="space-y-1">
            <div
              v-for="(row, rowIndex) in section.rows"
              :key="rowIndex"
              v-dompurify-html="formatListRow(row)"
              class="text-sm text-n-slate-12 py-1 px-2 bg-n-slate-1 rounded border-l-2 border-n-slate-6"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Footer -->
    <div
      v-if="footerText"
      class="whatsapp-footer mt-3 pt-2 border-t border-n-slate-4"
    >
      <div
        v-dompurify-html="footerText"
        class="text-xs text-n-slate-11 italic"
      />
    </div>

    <!-- WhatsApp Interactive Badge -->
    <div class="whatsapp-badge mt-2">
      <div class="flex items-center gap-1 text-xs text-n-slate-10">
        <svg class="w-3 h-3" viewBox="0 0 24 24" fill="currentColor">
          <path
            d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893A11.821 11.821 0 0020.885 3.382"
          />
        </svg>
        <span>{{ $t('CONVERSATION.WHATSAPP_INTERACTIVE_MESSAGE') }}</span>
      </div>
    </div>
  </BaseBubble>

  <!-- Fallback for when interactive content can't be rendered -->
  <BaseBubble v-else class="p-4">
    <div class="whatsapp-interactive-fallback">
      <p class="text-sm text-n-slate-11 mb-2">
        {{
          $t('CONVERSATION.WHATSAPP_INTERACTIVE_FALLBACK_TITLE') ||
          'WhatsApp Interactive Message'
        }}
      </p>
      <div
        v-dompurify-html="
          new MessageFormatter(
            content.value ||
              contentAttributes.value?.fallback_text ||
              'Interactive message content'
          ).formattedMessage
        "
        class="text-sm prose prose-bubble"
      />
      <!-- Debug info (development only) -->
      <details v-if="isDev" class="mt-2 text-xs text-n-slate-10">
        <summary>Debug Info</summary>
        <pre class="mt-1 p-2 bg-n-slate-2 rounded text-xs overflow-auto">{{
          JSON.stringify(
            {
              messageId: id.value,
              hasContentAttributes: !!contentAttributes.value,
              contentAttributesKeys: Object.keys(contentAttributes.value || {}),
              hasInteractivePayload: !!interactivePayload.value,
              interactivePayloadKeys: Object.keys(
                interactivePayload.value || {}
              ),
              interactiveType: interactiveType.value,
              isButton: isButtonTemplate.value,
              isList: isListTemplate.value,
              shouldRender: shouldRenderInteractive.value,
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
.whatsapp-interactive-bubble {
  @apply px-4 py-3;
}

.whatsapp-button:hover {
  transform: translateY(-1px);
}

.whatsapp-list-button:hover {
  transform: translateY(-1px);
}

.whatsapp-header img {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.whatsapp-badge {
  opacity: 0.8;
}
</style>
