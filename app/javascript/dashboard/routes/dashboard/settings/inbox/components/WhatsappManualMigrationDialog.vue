<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
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
const { t } = useI18n();

const WHATSAPP_MANUAL_MIGRATION_GUIDE_URL =
  'https://www.chatwoot.com/hc/user-guide/articles/1756799850-how-to-setup-a-whats_app-channel-manual-flow';

const dialogRef = ref(null);
const currentStep = ref(0);

const form = ref({
  wabaId: props.inbox.provider_config?.business_account_id || '',
  phoneNumberId: props.inbox.provider_config?.phone_number_id || '',
  displayPhoneNumber: props.inbox.phone_number || '',
  accessToken: '',
});

const copy = computed(() => ({
  eyebrow: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.EYEBROW`
  ),
  title: t(`INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.TITLE`),
  close: t(`INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.CLOSE`),
  actionRequiredTitle: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.ACTION_REQUIRED_TITLE`
  ),
  actionRequiredDescription: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.ACTION_REQUIRED_DESCRIPTION`
  ),
  guideLink: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.GUIDE_LINK`
  ),
  preservedTitle: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.PRESERVED_TITLE`
  ),
  preservedDescription: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.PRESERVED_DESCRIPTION`
  ),
  updatedTitle: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.UPDATED_TITLE`
  ),
  updatedDescription: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.UPDATED_DESCRIPTION`
  ),
  wabaId: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.WABA_ID`
  ),
  wabaPlaceholder: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.WABA_PLACEHOLDER`
  ),
  wabaHelp: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.WABA_HELP`
  ),
  phoneNumberId: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.PHONE_NUMBER_ID`
  ),
  phoneNumberPlaceholder: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.PHONE_NUMBER_PLACEHOLDER`
  ),
  phoneNumberHelp: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.PHONE_NUMBER_HELP`
  ),
  displayPhoneNumber: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.DISPLAY_PHONE_NUMBER`
  ),
  displayPhoneNumberPlaceholder: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.DISPLAY_PHONE_NUMBER_PLACEHOLDER`
  ),
  displayPhoneNumberHelp: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.DISPLAY_PHONE_NUMBER_HELP`
  ),
  accessToken: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.ACCESS_TOKEN`
  ),
  accessTokenPlaceholder: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.ACCESS_TOKEN_PLACEHOLDER`
  ),
  tokenHelpPrefix: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.TOKEN_HELP_PREFIX`
  ),
  tokenHelpMiddle: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.TOKEN_HELP_MIDDLE`
  ),
  tokenHelpSuffix: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.TOKEN_HELP_SUFFIX`
  ),
  messagingPermission: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.MESSAGING_PERMISSION`
  ),
  managementPermission: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.MANAGEMENT_PERMISSION`
  ),
  wabaAccessTitle: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.WABA_ACCESS_TITLE`
  ),
  wabaAccessDescription: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.WABA_ACCESS_DESCRIPTION`
  ),
  messagingAccessTitle: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.MESSAGING_ACCESS_TITLE`
  ),
  messagingAccessDescription: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.MESSAGING_ACCESS_DESCRIPTION`
  ),
  templateManagementTitle: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.TEMPLATE_MANAGEMENT_TITLE`
  ),
  templateManagementDescription: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.TEMPLATE_MANAGEMENT_DESCRIPTION`
  ),
  reviewTitle: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.REVIEW_TITLE`
  ),
  inbox: t(`INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.INBOX`),
  phoneNumber: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.PHONE_NUMBER`
  ),
  notEntered: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.NOT_ENTERED`
  ),
  previewNotice: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.PREVIEW_NOTICE`
  ),
  back: t(`INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.BACK`),
  cancel: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.CANCEL`
  ),
  continue: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.CONTINUE`
  ),
  reviewMigration: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.REVIEW_MIGRATION`
  ),
  reconnect: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.RECONNECT`
  ),
}));

const steps = computed(() => [
  {
    title: t(
      `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.STEPS.BEFORE_YOU_START.TITLE`
    ),
    description: t(
      `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.STEPS.BEFORE_YOU_START.DESCRIPTION`
    ),
  },
  {
    title: t(
      `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.STEPS.BUSINESS_DETAILS.TITLE`
    ),
    description: t(
      `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.STEPS.BUSINESS_DETAILS.DESCRIPTION`
    ),
  },
  {
    title: t(
      `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.STEPS.ACCESS_TOKEN.TITLE`
    ),
    description: t(
      `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.STEPS.ACCESS_TOKEN.DESCRIPTION`
    ),
  },
  {
    title: t(
      `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.STEPS.VERIFY_DETAILS.TITLE`
    ),
    description: t(
      `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.STEPS.VERIFY_DETAILS.DESCRIPTION`
    ),
  },
  {
    title: t(
      `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.STEPS.REVIEW_MIGRATION.TITLE`
    ),
    description: t(
      `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.STEPS.REVIEW_MIGRATION.DESCRIPTION`
    ),
  },
]);

const currentStepDetails = computed(() => steps.value[currentStep.value]);
const isFirstStep = computed(() => currentStep.value === 0);
const isLastStep = computed(() => currentStep.value === steps.value.length - 1);
const guideUrl = WHATSAPP_MANUAL_MIGRATION_GUIDE_URL;
const hasBusinessDetails = computed(
  () =>
    form.value.wabaId.trim() &&
    form.value.phoneNumberId.trim() &&
    form.value.displayPhoneNumber.trim()
);
const hasAccessToken = computed(() => form.value.accessToken.trim());
const canContinue = computed(() => {
  if (currentStep.value === 1) return hasBusinessDetails.value;
  if (currentStep.value === 2) return hasAccessToken.value;
  if (isLastStep.value) {
    return hasBusinessDetails.value && hasAccessToken.value;
  }

  return true;
});

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
  if (!canContinue.value) return;

  emit('reconnect', {
    wabaId: form.value.wabaId.trim(),
    phoneNumberId: form.value.phoneNumberId.trim(),
    displayPhoneNumber: form.value.displayPhoneNumber.trim(),
    accessToken: form.value.accessToken.trim(),
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

            <a
              :href="guideUrl"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1.5 text-sm font-medium text-n-blue-11 hover:underline"
            >
              {{ copy.guideLink }}
              <span class="i-lucide-external-link size-3.5" />
            </a>
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
              <span class="text-xs leading-5 text-n-slate-11">
                {{ copy.wabaHelp }}
              </span>
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
                <span class="text-xs leading-5 text-n-slate-11">
                  {{ copy.phoneNumberHelp }}
                </span>
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
                <span class="text-xs leading-5 text-n-slate-11">
                  {{ copy.displayPhoneNumberHelp }}
                </span>
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
              <span
                class="grid flex-shrink-0 rounded-full size-5 place-content-center border-2 border-n-teal-9 text-n-teal-9"
              >
                <span class="i-lucide-check size-3.5" />
              </span>
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
              <span
                class="grid flex-shrink-0 rounded-full size-5 place-content-center border-2 border-n-teal-9 text-n-teal-9"
              >
                <span class="i-lucide-check size-3.5" />
              </span>
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
              <span
                class="grid flex-shrink-0 rounded-full size-5 place-content-center border-2 border-n-teal-9 text-n-teal-9"
              >
                <span class="i-lucide-check size-3.5" />
              </span>
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
          <NextButton
            v-if="!isLastStep"
            :disabled="!canContinue"
            @click="goNext"
          >
            {{ currentStep === 3 ? copy.reviewMigration : copy.continue }}
          </NextButton>
          <NextButton
            v-else
            color="teal"
            :disabled="!canContinue"
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
