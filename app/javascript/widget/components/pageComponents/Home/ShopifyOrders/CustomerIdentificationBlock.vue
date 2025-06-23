<script setup>
import { defineProps, defineEmits, computed, reactive } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useStore } from 'dashboard/composables/store';
import { required, email } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';
import Button from 'shared/components/Button.vue';

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

const widgetColor = useMapGetter('appConfig/getWidgetColor');

const contactUiFlags = computed(() => store.getters['contacts/getUiFlags']);

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

      <Button
        :style="{ color: widgetColor }"
        :disabled="v$.email.$invalid"
        buttonType="submit"
      >
        <button>
          <span v-if="!contactUiFlags.isUpdating">
            {{ $t('VERIFY_EMAIL') }}
          </span>

          <Spinner v-else class="mx-2" />
        </button>
      </Button>
    </form>
    <div v-else>
      <Button>
        <button :style="{ color: widgetColor }" @click="onSubmit">
          {{ $t('VERIFY_EMAIL') }}
        </button>
      </Button>
    </div>
  </div>
</template>
