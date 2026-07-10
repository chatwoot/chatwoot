<script setup>
import { computed, ref } from 'vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['reconnect']);

const dialogRef = ref(null);
const currentStep = ref(0);

const form = ref({
  wabaId: props.inbox.provider_config?.business_account_id || '',
  phoneNumberId: props.inbox.provider_config?.phone_number_id || '',
  displayPhoneNumber: props.inbox.phone_number || '',
  accessToken: '',
});

const copy = {
  eyebrow: 'WhatsApp manual migration',
  title: 'Reconnect WhatsApp inbox',
  close: 'Close',
  actionRequiredTitle: 'Action required for this WhatsApp inbox',
  actionRequiredDescription:
    'Meta restrictions are affecting setup and management features. This guided flow updates the WhatsApp API connection without creating a new inbox.',
  preservedTitle: 'Preserved',
  preservedDescription:
    'Conversations, contacts, collaborators, routing, business hours, and inbox settings.',
  updatedTitle: 'Updated',
  updatedDescription:
    'WABA ID, phone number ID, access token, and webhook configuration.',
  wabaId: 'WABA ID',
  wabaPlaceholder: '987654321098765',
  phoneNumberId: 'Phone Number ID',
  phoneNumberPlaceholder: '112233445566778',
  displayPhoneNumber: 'Display phone number',
  displayPhoneNumberPlaceholder: '+16506675566',
  accessToken: 'Permanent access token or system user token',
  accessTokenPlaceholder: 'EAAB...',
  tokenHelpPrefix: 'The token must include',
  tokenHelpMiddle: 'Add',
  tokenHelpSuffix: 'for template sync and template management.',
  messagingPermission: 'whatsapp_business_messaging.',
  managementPermission: 'whatsapp_business_management',
  wabaAccessTitle: 'WABA and phone number access',
  wabaAccessDescription: 'Token can read the WABA and phone number.',
  messagingAccessTitle: 'Messaging access',
  messagingAccessDescription: 'Token can be used for WhatsApp Cloud messaging.',
  templateManagementTitle: 'Template management',
  templateManagementDescription:
    'The token can access WhatsApp message templates for sync and template management.',
  reviewTitle: 'Review before reconnecting',
  inbox: 'Inbox',
  phoneNumber: 'Phone number',
  notEntered: 'Not entered',
  previewNotice:
    'This preview does not save anything. In the production flow, the previous provider configuration should be kept for internal recovery before applying changes.',
  back: 'Back',
  cancel: 'Cancel',
  continue: 'Continue',
  reviewMigration: 'Review migration',
  reconnect: 'Reconnect WhatsApp inbox',
};

const steps = [
  {
    title: 'Before you start',
    description:
      'This reconnects the WhatsApp API details for this inbox. Conversations, collaborators, routing, business hours, CSAT, and bot settings will be preserved.',
  },
  {
    title: 'Business details',
    description:
      'Enter the WhatsApp assets from the customer Meta Business account.',
  },
  {
    title: 'Access token',
    description:
      'Paste a permanent access token or system user token with WhatsApp permissions.',
  },
  {
    title: 'Verify details',
    description:
      'Chatwoot will verify the token, WABA, phone number, and messaging access before applying changes.',
  },
  {
    title: 'Review migration',
    description:
      'Confirm the connection details before reconnecting this inbox.',
  },
];

const currentStepDetails = computed(() => steps[currentStep.value]);
const isFirstStep = computed(() => currentStep.value === 0);
const isLastStep = computed(() => currentStep.value === steps.length - 1);

const open = () => {
  currentStep.value = 0;
  dialogRef.value?.open();
};

const close = () => dialogRef.value?.close();

const goBack = () => {
  if (!isFirstStep.value) currentStep.value -= 1;
};

const goNext = () => {
  if (!isLastStep.value) currentStep.value += 1;
};

const reconnect = () => {
  emit('reconnect', {
    wabaId: form.value.wabaId,
    phoneNumberId: form.value.phoneNumberId,
    displayPhoneNumber: form.value.displayPhoneNumber,
    accessToken: form.value.accessToken,
  });
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="3xl"
    position="top"
    :show-confirm-button="false"
    :show-cancel-button="false"
    overflow-y-auto
  >
    <div class="flex flex-col gap-5">
      <div class="flex items-start justify-between gap-4">
        <div class="min-w-0">
          <p class="mb-1 text-sm font-medium text-n-slate-11">
            {{ copy.eyebrow }}
          </p>
          <h3 class="m-0 text-xl font-semibold text-n-slate-12">
            {{ copy.title }}
          </h3>
          <p class="mt-2 mb-0 text-sm text-n-slate-11">
            {{ currentStepDetails.description }}
          </p>
        </div>
        <button
          type="button"
          class="grid rounded-lg size-8 place-content-center text-n-slate-10 hover:bg-n-alpha-2"
          :aria-label="copy.close"
          @click="close"
        >
          <span class="i-lucide-x size-4" />
        </button>
      </div>

      <div class="grid gap-6 lg:grid-cols-[12rem,1fr]">
        <ol class="flex flex-col gap-1 p-0 m-0 list-none">
          <li
            v-for="(step, index) in steps"
            :key="step.title"
            class="flex items-center gap-2 px-2.5 py-2 text-sm rounded-lg"
            :class="
              index === currentStep
                ? 'bg-n-alpha-2 text-n-slate-12'
                : 'text-n-slate-11'
            "
          >
            <span
              class="grid text-xs font-medium rounded-full size-5 place-content-center"
              :class="
                index < currentStep
                  ? 'bg-n-teal-9 text-white'
                  : index === currentStep
                    ? 'bg-n-blue-9 text-white'
                    : 'bg-n-slate-4 text-n-slate-11'
              "
            >
              <span v-if="index < currentStep" class="i-lucide-check size-3" />
              <span v-else>{{ index + 1 }}</span>
            </span>
            <span class="truncate">{{ step.title }}</span>
          </li>
        </ol>

        <div class="min-w-0">
          <section v-if="currentStep === 0" class="flex flex-col gap-5">
            <div
              class="flex gap-3 p-3 border rounded-xl border-n-weak bg-n-alpha-2"
            >
              <span
                class="grid flex-shrink-0 rounded-lg size-8 place-content-center bg-n-amber-3 text-n-amber-11"
              >
                <span class="i-lucide-triangle-alert size-4" />
              </span>
              <div>
                <h4 class="mt-0 mb-1 text-base font-medium text-n-slate-12">
                  {{ copy.actionRequiredTitle }}
                </h4>
                <p class="m-0 text-sm text-n-slate-11">
                  {{ copy.actionRequiredDescription }}
                </p>
              </div>
            </div>

            <div class="grid gap-3 sm:grid-cols-2">
              <div
                class="flex flex-col gap-1 p-3 border rounded-lg border-n-weak"
              >
                <div class="flex items-center gap-2">
                  <span class="i-lucide-check size-4 text-n-teal-11" />
                  <p class="m-0 text-sm font-medium text-n-slate-12">
                    {{ copy.preservedTitle }}
                  </p>
                </div>
                <p class="m-0 text-sm text-n-slate-11">
                  {{ copy.preservedDescription }}
                </p>
              </div>
              <div
                class="flex flex-col gap-1 p-3 border rounded-lg border-n-weak"
              >
                <div class="flex items-center gap-2">
                  <span class="i-lucide-refresh-cw size-4 text-n-blue-11" />
                  <p class="m-0 text-sm font-medium text-n-slate-12">
                    {{ copy.updatedTitle }}
                  </p>
                </div>
                <p class="m-0 text-sm text-n-slate-11">
                  {{ copy.updatedDescription }}
                </p>
              </div>
            </div>
          </section>

          <section v-else-if="currentStep === 1" class="grid gap-4">
            <label class="flex flex-col gap-1">
              <span class="text-sm font-medium text-n-slate-12">
                {{ copy.wabaId }}
              </span>
              <input
                v-model="form.wabaId"
                class="w-full h-10 px-3 text-sm border-0 rounded-lg outline outline-1 outline-n-weak bg-n-alpha-2 text-n-slate-12"
                :placeholder="copy.wabaPlaceholder"
              />
            </label>
            <div class="grid gap-4 sm:grid-cols-2">
              <label class="flex flex-col gap-1">
                <span class="text-sm font-medium text-n-slate-12">
                  {{ copy.phoneNumberId }}
                </span>
                <input
                  v-model="form.phoneNumberId"
                  class="w-full h-10 px-3 text-sm border-0 rounded-lg outline outline-1 outline-n-weak bg-n-alpha-2 text-n-slate-12"
                  :placeholder="copy.phoneNumberPlaceholder"
                />
              </label>
              <label class="flex flex-col gap-1">
                <span class="text-sm font-medium text-n-slate-12">
                  {{ copy.displayPhoneNumber }}
                </span>
                <input
                  v-model="form.displayPhoneNumber"
                  class="w-full h-10 px-3 text-sm border-0 rounded-lg outline outline-1 outline-n-weak bg-n-alpha-2 text-n-slate-12"
                  :placeholder="copy.displayPhoneNumberPlaceholder"
                />
              </label>
            </div>
          </section>

          <section v-else-if="currentStep === 2" class="grid gap-4">
            <label class="flex flex-col gap-1">
              <span class="text-sm font-medium text-n-slate-12">
                {{ copy.accessToken }}
              </span>
              <textarea
                v-model="form.accessToken"
                rows="5"
                class="w-full p-3 text-sm border-0 rounded-lg resize-none outline outline-1 outline-n-weak bg-n-alpha-2 text-n-slate-12"
                :placeholder="copy.accessTokenPlaceholder"
              />
            </label>
            <div
              class="flex gap-3 p-3 border rounded-xl bg-n-blue-3 border-n-blue-4 text-n-blue-11"
            >
              <span class="i-lucide-info flex-shrink-0 size-4 mt-0.5" />
              <p class="m-0 text-sm">
                {{ copy.tokenHelpPrefix }}
                <code>{{ copy.messagingPermission }}</code>
                {{ copy.tokenHelpMiddle }}
                <code>{{ copy.managementPermission }}</code>
                {{ copy.tokenHelpSuffix }}
              </p>
            </div>
          </section>

          <section v-else-if="currentStep === 3" class="grid gap-2.5">
            <div
              class="flex items-center justify-between gap-3 p-3 border rounded-lg border-n-weak bg-n-solid-1"
            >
              <div>
                <p class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ copy.wabaAccessTitle }}
                </p>
                <p class="m-0 text-sm text-n-slate-11">
                  {{ copy.wabaAccessDescription }}
                </p>
              </div>
              <span class="i-lucide-circle-check size-5 text-n-teal-11" />
            </div>
            <div
              class="flex items-center justify-between gap-3 p-3 border rounded-lg border-n-weak bg-n-solid-1"
            >
              <div>
                <p class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ copy.messagingAccessTitle }}
                </p>
                <p class="m-0 text-sm text-n-slate-11">
                  {{ copy.messagingAccessDescription }}
                </p>
              </div>
              <span class="i-lucide-circle-check size-5 text-n-teal-11" />
            </div>
            <div
              class="flex items-center justify-between gap-3 p-3 border rounded-lg border-n-weak bg-n-solid-1"
            >
              <div>
                <p class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ copy.templateManagementTitle }}
                </p>
                <p class="m-0 text-sm text-n-slate-11">
                  {{ copy.templateManagementDescription }}
                </p>
              </div>
              <span class="i-lucide-circle-check size-5 text-n-teal-11" />
            </div>
          </section>

          <section
            v-else
            class="flex flex-col gap-4 p-4 border rounded-xl border-n-weak bg-n-solid-1"
          >
            <h4 class="m-0 text-base font-medium text-n-slate-12">
              {{ copy.reviewTitle }}
            </h4>
            <dl class="grid gap-3 m-0 sm:grid-cols-2">
              <div>
                <dt class="text-xs text-n-slate-11">{{ copy.inbox }}</dt>
                <dd class="m-0 text-sm font-medium text-n-slate-12">
                  {{ inbox.name }}
                </dd>
              </div>
              <div>
                <dt class="text-xs text-n-slate-11">
                  {{ copy.phoneNumber }}
                </dt>
                <dd class="m-0 text-sm font-medium text-n-slate-12">
                  {{ form.displayPhoneNumber || inbox.phone_number }}
                </dd>
              </div>
              <div>
                <dt class="text-xs text-n-slate-11">{{ copy.wabaId }}</dt>
                <dd class="m-0 text-sm font-medium text-n-slate-12">
                  {{ form.wabaId || copy.notEntered }}
                </dd>
              </div>
              <div>
                <dt class="text-xs text-n-slate-11">
                  {{ copy.phoneNumberId }}
                </dt>
                <dd class="m-0 text-sm font-medium text-n-slate-12">
                  {{ form.phoneNumberId || copy.notEntered }}
                </dd>
              </div>
            </dl>
            <div
              class="flex gap-3 p-3 border rounded-lg bg-n-alpha-2 border-n-weak text-n-slate-11"
            >
              <span
                class="i-lucide-lock-keyhole flex-shrink-0 size-4 mt-0.5 text-n-teal-11"
              />
              <p class="m-0 text-sm">
                {{ copy.previewNotice }}
              </p>
            </div>
          </section>
        </div>
      </div>

      <div class="flex items-center justify-between gap-3 pt-2">
        <NextButton
          variant="faded"
          color="slate"
          :disabled="isFirstStep"
          @click="goBack"
        >
          {{ copy.back }}
        </NextButton>
        <div class="flex items-center gap-2">
          <NextButton variant="ghost" color="slate" @click="close">
            {{ copy.cancel }}
          </NextButton>
          <NextButton v-if="!isLastStep" @click="goNext">
            {{ currentStep === 3 ? copy.reviewMigration : copy.continue }}
          </NextButton>
          <NextButton
            v-else
            color="teal"
            :is-loading="isLoading"
            @click="reconnect"
          >
            {{ copy.reconnect }}
          </NextButton>
        </div>
      </div>
    </div>
  </Dialog>
</template>
