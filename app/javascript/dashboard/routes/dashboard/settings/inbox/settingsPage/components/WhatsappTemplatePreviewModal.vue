<script setup>
import { computed, defineProps, defineEmits } from 'vue';
import { useI18n } from 'vue-i18n';

import Modal from 'dashboard/components/Modal.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  template: {
    type: Object,
    default: null,
  },
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'delete']);
const { t } = useI18n();

const localShow = computed({
  get: () => props.show,
  set: value => {
    if (!value) emit('close');
  },
});

const getStatusConfig = status => {
  const configs = {
    APPROVED: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.APPROVED'),
      icon: 'i-lucide-circle-check',
      class: 'text-n-teal-11 bg-n-teal-3',
    },
    PENDING: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.PENDING'),
      icon: 'i-lucide-clock',
      class: 'text-n-amber-11 bg-n-amber-3',
    },
    REJECTED: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.REJECTED'),
      icon: 'i-lucide-circle-x',
      class: 'text-n-ruby-10 bg-n-ruby-3',
    },
    PAUSED: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.PAUSED'),
      icon: 'i-lucide-pause-circle',
      class: 'text-n-slate-10 bg-n-slate-3',
    },
    IN_APPEAL: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.IN_APPEAL'),
      icon: 'i-lucide-message-square-warning',
      class: 'text-n-orange-10 bg-n-orange-3',
    },
    DISABLED: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.DISABLED'),
      icon: 'i-lucide-ban',
      class: 'text-n-slate-9 bg-n-slate-3',
    },
    FLAGGED: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.FLAGGED'),
      icon: 'i-lucide-flag',
      class: 'text-n-ruby-10 bg-n-ruby-3',
    },
    PENDING_DELETION: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.PENDING_DELETION'),
      icon: 'i-lucide-trash-2',
      class: 'text-n-ruby-9 bg-n-ruby-3',
    },
    REINSTATED: {
      label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.REINSTATED'),
      icon: 'i-lucide-rotate-ccw',
      class: 'text-n-teal-10 bg-n-teal-3',
    },
  };

  return (
    configs[status] || {
      label: status,
      icon: 'i-lucide-help-circle',
      class: 'text-n-slate-11 bg-n-slate-3',
    }
  );
};

const getCategoryLabel = category => {
  const labels = {
    MARKETING: t('INBOX_MGMT.WHATSAPP_TEMPLATES.CATEGORY.MARKETING'),
    UTILITY: t('INBOX_MGMT.WHATSAPP_TEMPLATES.CATEGORY.UTILITY'),
    AUTHENTICATION: t('INBOX_MGMT.WHATSAPP_TEMPLATES.CATEGORY.AUTHENTICATION'),
  };
  return labels[category] || category;
};

// Extract components from template
const headerComponent = computed(() => {
  return props.template?.components?.find(c => c.type === 'HEADER') || null;
});

const bodyComponent = computed(() => {
  return props.template?.components?.find(c => c.type === 'BODY') || null;
});

const footerComponent = computed(() => {
  return props.template?.components?.find(c => c.type === 'FOOTER') || null;
});

const buttonsComponent = computed(() => {
  return props.template?.components?.find(c => c.type === 'BUTTONS') || null;
});

// Highlight variables like {{1}}, {{2}} in the preview
const highlightVariables = text => {
  if (!text) return '';
  return text.replace(
    /\{\{(\d+)\}\}/g,
    '<span class="px-1 py-0.5 mx-0.5 text-xs font-medium rounded bg-n-teal-3 text-n-teal-11">{{$1}}</span>'
  );
};

// Statuses that prevent deletion (under review by Meta)
const PENDING_REVIEW_STATUSES = ['PENDING', 'IN_APPEAL'];

const isTemplateUnderReview = computed(() => {
  return PENDING_REVIEW_STATUSES.includes(props.template?.status);
});

const handleClose = () => {
  emit('close');
};

const handleDelete = () => {
  emit('delete', props.template);
};
</script>

<template>
  <Modal
    v-model:show="localShow"
    :on-close="handleClose"
    :show-close-button="true"
    size="medium"
  >
    <div class="p-6">
      <!-- Header -->
      <div class="mb-6">
        <div class="flex flex-wrap gap-2 items-center mb-2">
          <h2 class="text-xl font-semibold text-n-slate-12">
            {{ template?.name }}
          </h2>
          <span
            :class="[
              getStatusConfig(template?.status).class,
              'inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium',
            ]"
          >
            <Icon :icon="getStatusConfig(template?.status).icon" class="size-3" />
            {{ getStatusConfig(template?.status).label }}
          </span>
        </div>

        <!-- Template Details -->
        <div class="flex flex-wrap gap-4 text-sm text-n-slate-11">
          <span class="flex gap-1 items-center">
            <Icon icon="i-lucide-tag" class="size-3.5" />
            {{ getCategoryLabel(template?.category) }}
          </span>
          <span class="flex gap-1 items-center">
            <Icon icon="i-lucide-globe" class="size-3.5" />
            {{ template?.language }}
          </span>
          <span v-if="headerComponent?.format" class="flex gap-1 items-center">
            <Icon icon="i-lucide-image" class="size-3.5" />
            {{ headerComponent.format }}
          </span>
        </div>
      </div>

      <!-- Preview Section -->
      <div class="flex justify-center p-6 rounded-xl bg-n-slate-2">
        <!-- Phone Frame -->
        <div class="mx-auto w-[370px] rounded-[2rem] bg-[#E9F6F3] border border-n-slate-6 p-2">
          <!-- Phone Screen -->
          <div class="rounded-[1.5rem] bg-[#efeae2] overflow-hidden">
            <!-- WhatsApp Header -->
            <div class="flex items-center gap-3 px-4 py-3 bg-[#075e54] text-white">
              <div class="flex items-center justify-center w-8 h-8 rounded-full bg-white/20">
                <Icon icon="i-lucide-user" class="size-4" />
              </div>
              <span class="text-sm font-medium">WhatsApp</span>
            </div>

            <!-- Chat Area -->
            <div class="wa-chat-area relative p-3 min-h-[320px]">
              <!-- Message Bubble -->
              <div class="wa-bubble relative w-[330px] max-w-[330px] rounded-lg bg-white">
                <!-- Header Media Preview -->
                <div
                  v-if="headerComponent?.format === 'IMAGE'"
                  class="flex items-center justify-center h-28 bg-n-slate-3 rounded-t-lg"
                >
                  <Icon icon="i-lucide-image" class="size-10 text-n-slate-9" />
                </div>
                <div
                  v-else-if="headerComponent?.format === 'VIDEO'"
                  class="flex items-center justify-center h-28 bg-n-slate-3 rounded-t-lg"
                >
                  <Icon icon="i-lucide-play-circle" class="size-10 text-n-slate-9" />
                </div>
                <div
                  v-else-if="headerComponent?.format === 'DOCUMENT'"
                  class="flex items-center gap-2 p-3 bg-n-slate-3 rounded-t-lg"
                >
                  <Icon icon="i-lucide-file-text" class="size-8 text-n-ruby-9" />
                  <span class="text-xs text-n-slate-11">document.pdf</span>
                </div>

                <div class="p-3">
                  <!-- Header Text -->
                  <p
                    v-if="headerComponent?.format === 'TEXT' && headerComponent?.text"
                    class="mb-2 font-semibold whitespace-pre-wrap"
                    style="color: #1C2B33; font-family: 'Optimistic 95', system-ui, sans-serif; font-size: 16px;"
                    v-html="highlightVariables(headerComponent.text)"
                  />

                  <!-- Body -->
                  <p
                    v-if="bodyComponent?.text"
                    class="leading-relaxed whitespace-pre-wrap"
                    style="color: #111827; font-family: 'Segoe UI Historic', 'Segoe UI', Helvetica, Arial, sans-serif; font-size: 13.6px;"
                    v-html="highlightVariables(bodyComponent.text)"
                  />

                  <!-- Footer & Timestamp -->
                  <div class="flex items-end justify-between gap-2" style="padding: 0px 7px 0px 0px;">
                    <span
                      v-if="footerComponent?.text"
                      style="color: #00000073; font-family: 'Segoe UI Historic', 'Segoe UI', Helvetica, Arial, sans-serif; font-size: 13px; word-break: break-all;"
                    >
                      {{ footerComponent.text }}
                    </span>
                    <span v-else />
                    <span style="color: #00000066; font-family: 'Segoe UI Historic', 'Segoe UI', Helvetica, Arial, sans-serif; font-size: 11px; flex-shrink: 0;">12:00 pm</span>
                  </div>
                </div>

                <!-- Buttons -->
                <div v-if="buttonsComponent?.buttons?.length">
                  <div
                    v-for="(button, index) in buttonsComponent.buttons"
                    :key="index"
                    class="wa-button flex items-center justify-center gap-1"
                  >
                    <Icon
                      v-if="button.type === 'URL'"
                      icon="i-lucide-external-link"
                      class="size-4"
                    />
                    <Icon
                      v-else-if="button.type === 'PHONE_NUMBER'"
                      icon="i-lucide-phone"
                      class="size-4"
                    />
                    <Icon
                      v-else-if="button.type === 'QUICK_REPLY'"
                      icon="i-lucide-reply"
                      class="size-4"
                    />
                    <span>{{ button.text }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Preview Note -->
      <p class="mt-4 text-xs text-center text-n-slate-10">
        {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.PREVIEW.NOTE') }}
      </p>

      <!-- Footer Actions -->
      <div class="flex items-center justify-end gap-3 mt-6 pt-4 border-t border-n-weak">
        <NextButton
          faded
          slate
          :label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.CANCEL')"
          @click="handleClose"
        />
        <div
          v-tooltip="isTemplateUnderReview ? $t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_UNDER_REVIEW') : null"
        >
          <NextButton
            faded
            ruby
            icon="i-lucide-trash-2"
            :label="$t('INBOX_MGMT.DELETE.BUTTON_TEXT')"
            :disabled="isTemplateUnderReview"
            @click="handleDelete"
          />
        </div>
      </div>
    </div>
  </Modal>
</template>

<style scoped>
/* WhatsApp chat background pattern */
.wa-chat-area::before {
  background: url('@/dashboard/assets/images/whatsapp/wa-background.png');
  background-size: 366.5px 666px;
  content: "";
  height: 100%;
  left: 0;
  opacity: 0.06;
  position: absolute;
  top: 0;
  width: 100%;
  pointer-events: none;
}

/* WhatsApp message bubble tail */
.wa-bubble::before {
  background: url('@/dashboard/assets/images/whatsapp/wa-bubble-tail.png') 50% 50% no-repeat;
  background-size: contain;
  content: "";
  height: 31px;
  left: -12px;
  position: absolute;
  top: -6px;
  width: 12px;
}

/* Remove top-left border radius to connect with tail */
.wa-bubble {
  border-top-left-radius: 0 !important;
  box-shadow: 0 1px .5px #00000026;
}

/* WhatsApp button style */
.wa-button {
  border-top: 1px solid #DADDE1;
  color: #00a5f4;
  column-gap: 4px;
  font-size: 14px;
  height: 44px;
  line-height: 20px;
  white-space: pre-wrap;
}
</style>
