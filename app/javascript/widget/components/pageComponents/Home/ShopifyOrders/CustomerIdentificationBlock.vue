<script setup>
import { defineProps, defineEmits, computed, reactive } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useStore } from 'dashboard/composables/store';
import { required, email } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  has_email: {
    type: Boolean,
    required: true,
  },
});

const form = reactive({
  email: '',
});

const rules = {
  email: { required, email },
};

const v$ = useVuelidate(rules, form);

const store = useStore();

const emit = defineEmits(['view', 'viewAll']);

const widgetColor = useMapGetter('appConfig/getWidgetColor');

const onSubmit = () => {
  try {
    store.dispatch('contacts/verifyShopifyEmail', { email: form.email });
  } catch {
    // Handle error
  }
};
</script>

<template>
  <div class="flex flex-col gap-3">
    <h3 class="font-medium text-n-slate-12">
      {{ $t('SHOPIFY_LOGIN') }}
    </h3>
    <form
      v-if="!props.has_email"
      class="email-input-group h-10 flex my-2 mx-0 min-w-[200px] gap-4"
      @submit.prevent="onSubmit"
    >
      <input
        v-model="form.email"
        type="email"
        :placeholder="$t('EMAIL_PLACEHOLDER')"
        :class="{ error: v$.email.$error }"
        @input="v$.email.$touch"
        @keydown.enter="onSubmit"
        @blur="v$.email.$touch()"
      />

      <button
        class="button small"
        :disabled="v$.email.$invalid"
        :style="{
          background: widgetColor,
          borderColor: widgetColor,
          color: textColor,
        }"
      >
        <span v-if="!isUpdating">
          {{ $t('VERIFY_EMAIL') }}
          <FluentIcon icon="chevron-right" />
        </span>

        <Spinner v-else class="mx-2" />
      </button>
    </form>
    <div v-else>
      <button
        class="font-medium tracking-wide inline-flex"
        :style="{ color: widgetColor }"
        @click="$emit('viewAll')"
      >
        <span>{{ $t('SHOPIFY_ORDERS.VERIFY_EMAIL') }}</span>
      </button>
    </div>
  </div>
</template>
