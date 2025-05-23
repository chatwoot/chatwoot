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
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <div>
            <label for="name">{{ t('AGENT_MGMT.FORM_CREATE.AI_AGENT_NAME') }}</label>
            <Input id="name" v-model="state.name" :placeholder="t('AGENT_MGMT.FORM_CREATE.AI_AGENT_NAME')" />
          </div>
          <div>
            <label for="description">{{ t('AGENT_MGMT.FORM_CREATE.AI_AGENT_DESC') }}</label>
            <Input
              id="description"
              v-model="state.description"
              :placeholder="t('AGENT_MGMT.FORM_CREATE.AI_AGENT_DESC')"
            />
          </div>
        </div>
        <div>
          <label for="system_prompts">{{ t('AGENT_MGMT.FORM_CREATE.AI_AGENT_SYSTEM_PROMPT') }}</label>
          <TextArea
            id="system_prompts"
            v-model="state.system_prompts"
            custom-text-area-wrapper-class=""
            custom-text-area-class="!outline-none"
            auto-height
          />
        </div>
        <div>
          <label for="welcome_message">{{ t('AGENT_MGMT.FORM_CREATE.WELCOME_MESSAGE') }}</label>
          <TextArea
            id="welcome_message"
            v-model="state.welcoming_message"
            custom-text-area-wrapper-class=""
            custom-text-area-class="!outline-none"
            auto-height
          />
        </div>
        <div>
          <label for="routing_conditions">{{ t('AGENT_MGMT.FORM_CREATE.ROUTING_CONDITION') }}</label>
          <TextArea
            id="routing_conditions"
            v-model="state.routing_conditions"
            custom-text-area-wrapper-class=""
            custom-text-area-class="!outline-none"
            :placeholder="t('AGENT_MGMT.FORM_CREATE.ROUTING_CONDITION_PLACEHOLDER')"
            auto-height
          />
        </div>
        <button class="button self-start" type="submit" :disabled="loadingSave">
          <span v-if="loadingSave" class="mt-4 mb-4 spinner" />
          <span v-else>Simpan</span>
        </button>
      </div>
    </form>

    <div class="h-[600px] w-full lg:h-[500px] lg:w-[350px]">
      <div class="w-full bg-white rounded-xl shadow-lg overflow-hidden flex flex-col h-full">
        <div class="bg-green-600 px-4 py-2 flex justify-end items-center">
          <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
        </div>
        <div class="flex-1 flex flex-col space-y-4 p-4 overflow-y-auto">
          <div class="flex justify-start">
            <div class="bg-slate-50 px-4 py-3 rounded-lg text-sm max-w-[90%]">
              Hai! Ada yang bisa saya bantu?
            </div>
          </div>
          <!-- User Message (Right aligned) -->
          <div class="flex justify-end">
            <div class="bg-green-600 text-white px-4 py-2 rounded-lg text-sm max-w-[90%]">
              Hallo
            </div>
          </div>
          <!-- Bot Response (Left aligned) -->
          <div class="flex justify-start">
            <div class="bg-slate-50 px-4 py-3 rounded-lg text-sm max-w-[90%]">
              Halo! Ada yang bisa saya bantu terkait produk Cantika Glow? 😊
            </div>
          </div>
          <!-- User Message (Right aligned) -->
          <div class="flex justify-end">
            <div class="bg-green-600 text-white px-4 py-2 rounded-lg text-sm max-w-[90%]">
              Ada produk apa saja yang ada di Cantika Glow?
            </div>
          </div>
          <!-- Bot Response (Left aligned) -->
          <div class="flex justify-start">
            <div class="bg-slate-50 px-4 py-3 rounded-lg text-sm max-w-[90%]">
              Cantika Glow memiliki berbagai produk kecantikan yang terbagi dalam tiga kategori utama:

Skincare: Produk perawatan kulit untuk menjaga kesehatan dan kecantikan kulit Anda.
Makeup: Produk riasan untuk mempercantik penampilan.
Parfum: Wewangian untuk melengkapi gaya Anda.
Semua produk Cantika Glow sudah terdaftar di BPOM, jadi aman digunakan. Ada kategori tertentu yang ingin Anda eksplor lebih lanjut? 😊
            </div>
          </div>
        </div>
        <div class="flex items-center  p-4">
          <input type="text" placeholder="Type your question" class="flex-grow p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-green-600">
          <button class="ml-2 bg-green-600 text-white p-2 rounded-lg hover:bg-green-700 relative bottom-2">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12l15-6-6 15-2.25-6-6.75-3z" />
            </svg>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
