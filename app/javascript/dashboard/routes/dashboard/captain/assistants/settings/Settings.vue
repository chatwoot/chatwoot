<script setup>
import { computed, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAccount } from 'dashboard/composables/useAccount';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import SettingsHeader from 'dashboard/components-next/captain/pageComponents/settings/SettingsHeader.vue';
import AssistantBasicSettingsForm from 'dashboard/components-next/captain/pageComponents/assistant/settings/AssistantBasicSettingsForm.vue';
import AssistantSystemSettingsForm from 'dashboard/components-next/captain/pageComponents/assistant/settings/AssistantSystemSettingsForm.vue';
import AssistantControlItems from 'dashboard/components-next/captain/pageComponents/assistant/settings/AssistantControlItems.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();

const isCaptainV2Enabled = computed(() =>
  isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_V2)
);
const route = useRoute();
const router = useRouter();
const store = useStore();

const deleteAssistantDialog = ref(null);

const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const assistants = useMapGetter('captainAssistants/getRecords');
const isFetching = computed(() => uiFlags.value.fetchingItem);
const assistantId = computed(() => Number(route.params.assistantId));
const assistant = computed(() =>
  store.getters['captainAssistants/getRecord'](assistantId.value)
);

const controlItems = computed(() => {
  return [
    {
      name: t(
        'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.GUARDRAILS.TITLE'
      ),
      description: t(
        'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.GUARDRAILS.DESCRIPTION'
      ),
      routeName: 'captain_assistants_guardrails_index',
      icon: 'i-lucide-shield-check',
    },
    {
      name: t(
        'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.RESPONSE_GUIDELINES.TITLE'
      ),
      description: t(
        'CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.OPTIONS.RESPONSE_GUIDELINES.DESCRIPTION'
      ),
      routeName: 'captain_assistants_guidelines_index',
      icon: 'i-lucide-book-open',
    },
  ];
});

const handleSubmit = async updatedAssistant => {
  try {
    await store.dispatch('captainAssistants/update', {
      id: assistantId.value,
      ...updatedAssistant,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.EDIT.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('CAPTAIN.ASSISTANTS.EDIT.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const handleDelete = () => {
  deleteAssistantDialog.value.dialogRef.open();
};

const handleDeleteSuccess = () => {
  // Get remaining assistants after deletion
  const remainingAssistants = assistants.value.filter(
    a => a.id !== assistantId.value
  );

  if (remainingAssistants.length > 0) {
    // Navigate to the first available assistant's settings
    const nextAssistant = remainingAssistants[0];
    router.push({
      name: 'captain_assistants_settings_index',
      params: {
        accountId: route.params.accountId,
        assistantId: nextAssistant.id,
      },
    });
  } else {
    // No assistants left, redirect to create assistant page
    router.push({
      name: 'captain_assistants_create_index',
      params: { accountId: route.params.accountId },
    });
  }
};
</script>

<template>
  <PageLayout
    :is-fetching="isFetching"
    :show-pagination-footer="false"
    :show-know-more="false"
    :class="{
      '[&>header>div]:max-w-[80rem] [&>main>div]:max-w-[80rem]':
        isCaptainV2Enabled,
    }"
  >
    <template #body>
      <div
        class="assistant-settings-page mx-auto w-full max-w-[80rem] space-y-10 pb-8 text-on-surface antialiased selection:bg-secondary/30"
        :class="{
          'grid grid-cols-1 gap-10 lg:grid-cols-3 lg:gap-12':
            isCaptainV2Enabled,
        }"
      >
        <div
          class="flex flex-col space-y-10"
          :class="{ 'lg:col-span-2': isCaptainV2Enabled }"
        >
          <section class="space-y-4">
            <SettingsHeader
              icon="i-lucide-sliders-horizontal"
              :heading="t('CAPTAIN.ASSISTANTS.SETTINGS.BASIC_SETTINGS.TITLE')"
              :description="
                t('CAPTAIN.ASSISTANTS.SETTINGS.BASIC_SETTINGS.DESCRIPTION')
              "
            />
            <AssistantBasicSettingsForm
              :assistant="assistant"
              @submit="handleSubmit"
            />
          </section>

          <div class="border-t border-outline-variant/15" />

          <section class="space-y-4">
            <SettingsHeader
              icon="i-lucide-messages-square"
              :heading="t('CAPTAIN.ASSISTANTS.SETTINGS.SYSTEM_SETTINGS.TITLE')"
              :description="
                t('CAPTAIN.ASSISTANTS.SETTINGS.SYSTEM_SETTINGS.DESCRIPTION')
              "
            />
            <AssistantSystemSettingsForm
              :assistant="assistant"
              @submit="handleSubmit"
            />
          </section>

          <div class="border-t border-outline-variant/15" />

          <section
            class="rounded-xl border border-outline-variant/10 bg-surface-container-low p-6 shadow-sm"
          >
            <div
              class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between"
            >
              <div class="flex gap-3">
                <Icon
                  icon="i-lucide-alert-triangle"
                  class="mt-0.5 size-5 shrink-0 text-error"
                />
                <div class="min-w-0 space-y-1">
                  <h3 class="text-base font-semibold text-on-surface">
                    {{ t('CAPTAIN.ASSISTANTS.SETTINGS.DELETE.TITLE') }}
                  </h3>
                  <p class="mb-0 text-sm text-on-surface-variant">
                    {{ t('CAPTAIN.ASSISTANTS.SETTINGS.DELETE.DESCRIPTION') }}
                  </p>
                </div>
              </div>
              <div class="shrink-0 sm:pt-0.5">
                <Button
                  :label="
                    t('CAPTAIN.ASSISTANTS.SETTINGS.DELETE.BUTTON_TEXT', {
                      assistantName: assistant.name,
                    })
                  "
                  color="ruby"
                  class="max-w-56 !w-fit"
                  @click="handleDelete"
                />
              </div>
            </div>
          </section>
        </div>

        <aside
          v-if="isCaptainV2Enabled"
          class="flex flex-col space-y-4 lg:col-span-1"
        >
          <SettingsHeader
            icon="i-lucide-layout-grid"
            :heading="t('CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.TITLE')"
            :description="
              t('CAPTAIN.ASSISTANTS.SETTINGS.CONTROL_ITEMS.DESCRIPTION')
            "
          />
          <div class="flex flex-col gap-4">
            <AssistantControlItems
              v-for="item in controlItems"
              :key="item.name"
              :control-item="item"
            />
          </div>
        </aside>
      </div>
    </template>
    <DeleteDialog
      v-if="assistant"
      ref="deleteAssistantDialog"
      :entity="assistant"
      type="Assistants"
      translation-key="ASSISTANTS"
      @delete-success="handleDeleteSuccess"
    />
  </PageLayout>
</template>
