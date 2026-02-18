<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useIntegrationHook } from 'dashboard/composables/useIntegrationHook';
import { FormKit } from '@formkit/vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  integrationId: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const { integration, hasConnectedHooks } = useIntegrationHook(
  props.integrationId
);

const isUpdating = ref(false);
const showModal = ref(false);

const zohoHook = computed(() => integration.value.hooks?.[0]);
const zohoSettings = computed(() => zohoHook.value?.settings || {});
const hasDeskSoid = computed(() => !!zohoSettings.value.desk_soid);

const values = ref({});

function openModal() {
  values.value = {
    client_id: zohoSettings.value.client_id || '',
    client_secret: zohoSettings.value.client_secret || '',
    desk_soid: zohoSettings.value.desk_soid || '',
  };
  showModal.value = true;
}

function closeModal() {
  showModal.value = false;
}

async function submitForm() {
  isUpdating.value = true;
  try {
    await store.dispatch('integrations/updateHook', {
      hookId: zohoHook.value.id,
      hookData: {
        hook: {
          settings: {
            ...zohoSettings.value,
            desk_soid: values.value.desk_soid.trim(),
          },
        },
      },
    });
    useAlert(t('CAPTAIN.ZOHO_DESK.API.SUCCESS_MESSAGE'));
    closeModal();
  } catch {
    useAlert(t('CAPTAIN.ZOHO_DESK.API.ERROR_MESSAGE'));
  } finally {
    isUpdating.value = false;
  }
}

async function removeDeskSoid() {
  isUpdating.value = true;
  try {
    const { desk_soid: _, ...settingsWithoutDesk } = zohoSettings.value;
    await store.dispatch('integrations/updateHook', {
      hookId: zohoHook.value.id,
      hookData: {
        hook: {
          settings: settingsWithoutDesk,
        },
      },
    });
    useAlert(t('CAPTAIN.ZOHO_DESK.API.DISCONNECT_MESSAGE'));
  } catch {
    useAlert(t('CAPTAIN.ZOHO_DESK.API.ERROR_MESSAGE'));
  } finally {
    isUpdating.value = false;
  }
}
</script>

<template>
  <div
    v-if="hasConnectedHooks"
    class="outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow flex-grow overflow-auto p-4"
  >
    <div class="flex items-center justify-center">
      <div class="flex h-16 w-16 items-center justify-center">
        <img
          :src="`/dashboard/images/integrations/zoho_desk.png`"
          class="max-w-full rounded-md border border-n-weak shadow-sm block dark:hidden bg-n-alpha-3 dark:bg-n-alpha-2"
        />
        <img
          :src="`/dashboard/images/integrations/zoho_desk-dark.png`"
          class="max-w-full rounded-md border border-n-weak shadow-sm hidden dark:block bg-n-alpha-3 dark:bg-n-alpha-2"
        />
      </div>
      <div class="flex flex-col justify-center m-0 mx-4 flex-1">
        <h3 class="mb-1 text-xl font-medium text-n-slate-12">
          {{ $t('CAPTAIN.ZOHO_DESK.TITLE') }}
        </h3>
        <p class="text-n-slate-11 text-sm leading-6">
          {{ $t('CAPTAIN.ZOHO_DESK.DESCRIPTION') }}
        </p>
      </div>
      <div class="flex justify-center items-center mb-0 w-[15%]">
        <div v-if="hasDeskSoid">
          <Button
            ruby
            faded
            :label="$t('INTEGRATION_APPS.DISCONNECT.BUTTON_TEXT')"
            :is-loading="isUpdating"
            @click="removeDeskSoid"
          />
        </div>
        <div v-else>
          <Button
            blue
            faded
            :label="$t('INTEGRATION_APPS.CONNECT.BUTTON_TEXT')"
            @click="openModal"
          />
        </div>
      </div>
    </div>

    <woot-modal v-model:show="showModal" :on-close="closeModal">
      <div class="flex flex-col h-auto overflow-auto integration-hooks">
        <woot-modal-header
          :header-title="$t('CAPTAIN.ZOHO_DESK.TITLE')"
          :header-content="$t('CAPTAIN.ZOHO_DESK.DESCRIPTION')"
        />
        <FormKit
          v-model="values"
          type="form"
          form-class="w-full grid gap-4"
          :submit-attrs="{
            inputClass: 'hidden',
            wrapperClass: 'hidden',
          }"
          :incomplete-message="false"
          @submit="submitForm"
        >
          <FormKit
            type="text"
            name="client_id"
            label="Client ID"
            disabled
            :help="$t('CAPTAIN.ZOHO_DESK.INHERITED_FROM_CRM')"
          />
          <FormKit
            type="text"
            name="client_secret"
            label="Client Secret"
            input-type="password"
            disabled
            :help="$t('CAPTAIN.ZOHO_DESK.INHERITED_FROM_CRM')"
          />
          <FormKit
            type="text"
            name="desk_soid"
            :label="$t('CAPTAIN.ZOHO_DESK.FORM.DESK_SOID_LABEL')"
            :placeholder="$t('CAPTAIN.ZOHO_DESK.FORM.DESK_SOID_PLACEHOLDER')"
            validation="required"
            :help="$t('CAPTAIN.ZOHO_DESK.FORM.DESK_SOID_HELP')"
          />
          <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
            <Button
              faded
              slate
              type="reset"
              :label="$t('CAPTAIN.ZOHO_DESK.FORM.CANCEL')"
              @click.prevent="closeModal"
            />
            <Button
              type="submit"
              :label="$t('CAPTAIN.ZOHO_DESK.FORM.SUBMIT')"
              :is-loading="isUpdating"
            />
          </div>
        </FormKit>
      </div>
    </woot-modal>
  </div>
</template>
