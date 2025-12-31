<script setup>
import { inject, computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useVuelidate } from '@vuelidate/core';
import { required, maxLength } from '@vuelidate/validators';
import { useAccount } from 'dashboard/composables/useAccount';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const { t } = useI18n();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const wizardData = inject('wizardData');

// Local state for vuelidate that syncs with wizardData
const localName = ref(wizardData.value.name || '');

// Sync localName back to wizardData
watch(localName, newVal => {
  wizardData.value.name = newVal;
});

// Sync wizardData.name to localName (for initial load)
watch(
  () => wizardData.value.name,
  newVal => {
    if (newVal !== localName.value) {
      localName.value = newVal || '';
    }
  }
);

const rules = {
  localName: { required, maxLength: maxLength(100) },
};

const v$ = useVuelidate(rules, { localName });

const nameError = computed(() => {
  if (v$.value.localName.$error) {
    return t('ALOO.FORM.NAME.ERROR');
  }
  return '';
});

const touchName = () => {
  v$.value.localName.$touch();
};

const goToNext = async () => {
  // Touch the field first to trigger validation display
  v$.value.localName.$touch();

  // Direct check for empty name
  if (!localName.value || !localName.value.trim()) {
    return;
  }

  const isValid = await v$.value.$validate();
  if (isValid) {
    router.push(accountScopedRoute('settings_aloo_new_personality'));
  }
};

const goBack = () => {
  router.push(accountScopedRoute('settings_aloo_list'));
};
</script>

<template>
  <div class="flex flex-col h-full p-8">
    <div class="flex-1">
      <h2 class="text-xl font-semibold text-n-slate-12 mb-2">
        {{ $t('ALOO.WIZARD.STEP_1') }}
      </h2>
      <p class="text-n-slate-11 mb-8">
        {{ $t('ALOO.WIZARD.STEP_1_DESCRIPTION') }}
      </p>

      <div class="space-y-6 max-w-lg">
        <Input
          v-model="localName"
          :label="$t('ALOO.FORM.NAME.LABEL')"
          :placeholder="$t('ALOO.FORM.NAME.PLACEHOLDER')"
          :message="nameError"
          :message-type="nameError ? 'error' : ''"
          @blur="touchName"
        />

        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
            {{ $t('ALOO.FORM.DESCRIPTION.LABEL') }}
          </label>
          <textarea
            v-model="wizardData.description"
            :placeholder="$t('ALOO.FORM.DESCRIPTION.PLACEHOLDER')"
            rows="4"
            class="w-full px-3 py-2 text-sm border rounded-lg resize-none border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7 focus:border-transparent"
          />
        </div>
      </div>
    </div>

    <div class="flex justify-between pt-6 border-t border-n-weak">
      <Button variant="faded" slate @click="goBack">
        {{ $t('ALOO.ACTIONS.CANCEL') }}
      </Button>
      <Button @click="goToNext">
        {{ $t('ALOO.ACTIONS.NEXT') }}
      </Button>
    </div>
  </div>
</template>
