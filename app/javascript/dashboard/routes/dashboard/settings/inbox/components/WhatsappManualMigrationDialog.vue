<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useBranding } from 'shared/composables/useBranding';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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
const { replaceInstallationName } = useBranding();

const WHATSAPP_MANUAL_MIGRATION_GUIDE_URL =
  'https://www.chatwoot.com/hc/user-guide/articles/1756799850-how-to-setup-a-whats_app-channel-manual-flow';

const dialogRef = ref(null);
const currentStep = ref(0);

const buildForm = () => ({
  wabaId: props.inbox.provider_config?.business_account_id || '',
  phoneNumberId: props.inbox.provider_config?.phone_number_id || '',
  displayPhoneNumber: props.inbox.phone_number || '',
  accessToken: '',
});

const form = ref(buildForm());

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
  verifyNotice: t(
    `INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANUAL_MIGRATION.DIALOG.VERIFY_NOTICE`
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
  () => form.value.wabaId.trim() && form.value.phoneNumberId.trim()
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
  form.value = buildForm();
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
    <div class="flex flex-col gap-5 h-[24rem]">
      <div class="flex items-start justify-between gap-4">
        <div class="min-w-0">
          <p class="mb-1 text-sm font-medium text-n-slate-11">
            {{ copy.eyebrow }}
          </p>
          <h3 class="m-0 text-xl font-semibold text-n-slate-12">
            {{ copy.title }}
          </h3>
          <p class="mt-2 mb-0 text-sm text-n-slate-11 min-h-[2.5rem]">
            {{ replaceInstallationName(currentStepDetails.description) }}
          </p>
        </div>
        <NextButton
          v-tooltip="copy.close"
          type="button"
          variant="ghost"
          color="slate"
          size="sm"
          icon="i-lucide-x"
          :aria-label="copy.close"
          @click="close"
        />
      </div>

      <div
        class="grid flex-1 gap-6 overflow-y-auto min-h-0 grid-cols-[11rem,1fr]"
      >
        <ol class="flex flex-col p-0 m-0 list-none">
          <li
            v-for="(step, index) in steps"
            :key="step.title"
            class="relative flex gap-3"
          >
            <div class="relative flex flex-col items-center">
              <span
                class="z-10 grid text-xs font-semibold transition-colors rounded-full size-6 place-content-center"
                :class="
                  index < currentStep
                    ? 'bg-n-teal-9 text-white'
                    : index === currentStep
                      ? 'bg-n-blue-9 text-white'
                      : 'bg-n-alpha-2 text-n-slate-11 outline outline-1 outline-n-container -outline-offset-1'
                "
              >
                <Icon
                  v-if="index < currentStep"
                  icon="i-lucide-check"
                  class="size-3.5"
                />
                <span v-else>{{ index + 1 }}</span>
              </span>
              <span
                v-if="index < steps.length - 1"
                class="flex-1 my-1 rounded-full w-0.5"
                :class="index < currentStep ? 'bg-n-teal-9' : 'bg-n-slate-4'"
              />
            </div>
            <span
              class="text-sm leading-6 truncate min-w-0"
              :class="[
                index < steps.length - 1 ? 'pb-6' : '',
                index === currentStep
                  ? 'font-medium text-n-slate-12'
                  : 'text-n-slate-11',
              ]"
            >
              {{ step.title }}
            </span>
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
                <Icon icon="i-lucide-triangle-alert" class="size-4" />
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
                class="flex flex-col gap-1 p-3 rounded-xl bg-n-solid-2 outline outline-1 outline-n-container -outline-offset-1"
              >
                <div class="flex items-center gap-2">
                  <Icon icon="i-lucide-check" class="size-4 text-n-teal-11" />
                  <p class="m-0 text-sm font-medium text-n-slate-12">
                    {{ copy.preservedTitle }}
                  </p>
                </div>
                <p class="m-0 text-sm text-n-slate-11">
                  {{ copy.preservedDescription }}
                </p>
              </div>
              <div
                class="flex flex-col gap-1 p-3 rounded-xl bg-n-solid-2 outline outline-1 outline-n-container -outline-offset-1"
              >
                <div class="flex items-center gap-2">
                  <Icon
                    icon="i-lucide-refresh-cw"
                    class="size-4 text-n-blue-11"
                  />
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
              <Icon icon="i-lucide-external-link" class="size-3.5" />
            </a>
          </section>

          <section v-else-if="currentStep === 1" class="grid gap-4">
            <div class="flex flex-col gap-1">
              <Input
                v-model="form.wabaId"
                :label="copy.wabaId"
                :placeholder="copy.wabaPlaceholder"
              />
              <span class="text-xs leading-5 text-n-slate-11">
                {{ copy.wabaHelp }}
              </span>
            </div>
            <div class="grid gap-4 sm:grid-cols-2">
              <div class="flex flex-col gap-1">
                <Input
                  v-model="form.phoneNumberId"
                  :label="copy.phoneNumberId"
                  :placeholder="copy.phoneNumberPlaceholder"
                />
                <span class="text-xs leading-5 text-n-slate-11">
                  {{ copy.phoneNumberHelp }}
                </span>
              </div>
              <div class="flex flex-col gap-1">
                <Input
                  v-model="form.displayPhoneNumber"
                  disabled
                  :label="copy.displayPhoneNumber"
                  :placeholder="copy.displayPhoneNumberPlaceholder"
                />
                <span class="text-xs leading-5 text-n-slate-11">
                  {{ copy.displayPhoneNumberHelp }}
                </span>
              </div>
            </div>
          </section>

          <section v-else-if="currentStep === 2" class="grid gap-4">
            <TextArea
              v-model="form.accessToken"
              :label="copy.accessToken"
              :placeholder="copy.accessTokenPlaceholder"
              auto-height
              min-height="6rem"
              max-height="12rem"
            />
            <div
              class="flex gap-3 p-3 border rounded-xl bg-n-blue-3 border-n-blue-4 text-n-blue-11"
            >
              <Icon icon="i-lucide-info" class="flex-shrink-0 size-4 mt-0.5" />
              <p class="m-0 text-sm">
                {{ copy.tokenHelpPrefix }}
                <code>{{ copy.messagingPermission }}</code>
                {{ copy.tokenHelpMiddle }}
                <code>{{ copy.managementPermission }}</code>
                {{ copy.tokenHelpSuffix }}
              </p>
            </div>
          </section>

          <section
            v-else
            class="flex flex-col gap-4 p-4 rounded-xl bg-n-solid-2 outline outline-1 outline-n-container -outline-offset-1"
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
              <Icon
                icon="i-lucide-shield-check"
                class="flex-shrink-0 size-4 mt-0.5 text-n-teal-11"
              />
              <p class="m-0 text-sm">
                {{ replaceInstallationName(copy.verifyNotice) }}
              </p>
            </div>
          </section>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <NextButton
          type="button"
          variant="faded"
          color="slate"
          :disabled="isFirstStep"
          @click="goBack"
        >
          {{ copy.back }}
        </NextButton>
        <div class="flex items-center gap-2">
          <NextButton
            type="button"
            variant="ghost"
            color="slate"
            @click="close"
          >
            {{ copy.cancel }}
          </NextButton>
          <NextButton
            v-if="!isLastStep"
            type="button"
            :disabled="!canContinue"
            @click="goNext"
          >
            {{ currentStep === 2 ? copy.reviewMigration : copy.continue }}
          </NextButton>
          <NextButton
            v-else
            type="button"
            color="teal"
            :disabled="!canContinue"
            :is-loading="isLoading"
            @click="reconnect"
          >
            {{ copy.reconnect }}
          </NextButton>
        </div>
      </div>
    </template>
  </Dialog>
</template>
