<script setup>
import {
  computed,
  nextTick,
  reactive,
  ref,
  useTemplateRef,
  watch,
  watchEffect,
} from 'vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import { required } from '@vuelidate/validators';
import useVuelidate from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import aiAgents from '../../../api/aiAgents';
const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const chatflowId = ref();
watch(
  () => props.data,
  v => {
    chatflowId.value = v?.chat_flow_id;
  },
  {
    immediate: true,
  }
);

const state = reactive({
  name: '',
  description: '',
  system_prompts: '',
  welcoming_message: '',
  routing_condition: '',
});
const rules = {
  name: { required },
  description: {},
  system_prompts: { required },
  welcoming_message: {},
  routing_conditions: {},
};

const v$ = useVuelidate(rules, state);

watch(
  () => props.data,
  v => {
    if (v) {
      Object.assign(state, {
        name: v.name,
        description: v.description || '',
        system_prompts: v.system_prompts || '',
        welcoming_message: v.welcoming_message || '',
        routing_conditions: v.routing_conditions || '',
      });
    }
  },
  {
    immediate: true,
  }
);

const loadingSave = ref(false);
async function submit() {
  if (loadingSave.value) {
    return;
  }

  if (!(await v$.value.$validate())) {
    return;
  }

  try {
    loadingSave.value = true;
    const request = {
      ...state,
    };
    await aiAgents.updateAgent(props.data.id, request);
    const detailAgent = await aiAgents
      .detailAgent(props.data.id)
      .then(v => v?.data);
    chatflowId.value = undefined;
    nextTick(() => {
      chatflowId.value = detailAgent?.chat_flow_id;
    });
    useAlert('Berhasil disimpan');
  } finally {
    loadingSave.value = false;
  }
}

const previewUrl = computed(() => {
  return `https://ai.radyalabs.id/chatbot/${chatflowId.value}`;
});
</script>

<template>
  <div class="flex flex-col lg:flex-row justify-stretch gap-4">
    <form class="lg:flex-1 lg:min-w-0" @submit.prevent="() => submit()">
      <div class="flex flex-col space-y-3">
        <div>
          <label for="name">Nama Agen AI</label>
          <Input id="name" v-model="state.name" placeholder="Nama Agen AI" />
        </div>
        <div>
          <label for="description">Deskripsi Agen AI</label>
          <Input
            id="description"
            v-model="state.description"
            placeholder="Deskripsi Agen AI"
          />
        </div>
        <div>
          <label for="system_prompts">Perintah AI</label>
          <TextArea
            id="system_prompts"
            v-model="state.system_prompts"
            custom-text-area-wrapper-class=""
            custom-text-area-class="!outline-none"
            auto-height
          />
        </div>
        <div>
          <label for="welcome_message">Pesan Selamat Datang</label>
          <TextArea
            id="welcome_message"
            v-model="state.welcoming_message"
            custom-text-area-wrapper-class=""
            custom-text-area-class="!outline-none"
            auto-height
          />
        </div>
        <div>
          <label for="routing_conditions">Kondisi Pengalihan</label>
          <TextArea
            id="routing_conditions"
            v-model="state.routing_conditions"
            custom-text-area-wrapper-class=""
            custom-text-area-class="!outline-none"
            auto-height
          />
        </div>
        <button class="button self-start" type="submit" :disabled="loadingSave">
          <span v-if="loadingSave" class="mt-4 mb-4 spinner" />
          <span v-else>Simpan</span>
        </button>
      </div>
    </form>

    <div v-if="previewUrl" class="h-[600px] w-full lg:h-[500px] lg:w-[350px]">
      <iframe
        height="100%"
        width="100%"
        class="rounded-lg shadow-md border border-slate-50 dark:border-transparent outline-none"
        :src="previewUrl"
      />
    </div>
  </div>
</template>
