<template>
    <div class="flex flex-col lg:flex-row justify-stretch gap-4">
        <form class="lg:flex-1 lg:min-w-0" @submit.prevent="() => submit()">
            <div class="flex flex-col space-y-3">
                <div>
                    <label for="name">Nama Agen AI</label>
                    <Input id="name" :placeholder="'Nama Agen AI'" v-model="state.name" />
                </div>
                <div>
                    <label for="description">Deskripsi Agen AI</label>
                    <Input id="description" :placeholder="'Deskripsi Agen AI'" v-model="state.description" />
                </div>
                <div>
                    <label for="system_prompts">Perintah AI</label>
                    <TextArea id="system_prompts" custom-text-area-wrapper-class=""
                        custom-text-area-class="!outline-none" autoHeight v-model="state.system_prompt" />
                </div>
                <div>
                    <label for="welcome_message">Welcome Message</label>
                    <TextArea id="welcome_message" custom-text-area-wrapper-class=""
                        custom-text-area-class="!outline-none" autoHeight v-model="state.welcoming_message" />
                </div>
                <button class="button self-start" type="submit" :disabled="loadingSave">
                    <span v-if="loadingSave" class="mt-4 mb-4 spinner" />
                    <span v-else>Simpan</span>
                </button>
            </div>
        </form>

        <div class="h-[600px] w-full lg:h-[500px] lg:w-[350px]">
            <iframe height="100%" width="100%" class="rounded-lg shadow-md border border-slate-50 dark:border-transparent outline-none" :src="previewUrl"></iframe>
        </div>
    </div>
</template>

<script setup>
import { reactive, ref, watch } from 'vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import { required } from '@vuelidate/validators';
import useVuelidate from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import aiAgents from '../../../api/aiAgents';
const { t } = useI18n()

const props = defineProps({
    data: {
        type: Object,
        required: true,
    },
});

const state = reactive({
    name: '',
    description: '',
    system_prompt: '',
    welcoming_message: '',
})
const rules = {
    name: { required },
    description: {},
    system_prompt: { required },
    welcoming_message: {},
}

const v$ = useVuelidate(rules, state)

watch(() => props.data, v => {
    if (v) {
        Object.assign(state, {
            name: v.name,
            description: v.description || '',
            system_prompt: v.system_prompts || '',
            welcoming_message: v.welcoming_message || '',
        })
    }
}, {
    immediate: true,
})

const loadingSave = ref(false)
async function submit() {
    if (loadingSave.value) {
        return
    }

    if (!(await v$.value.$validate())) {
        return
    }

    try {
        loadingSave.value = true
        const request = {
            ...state,
        }
        await aiAgents.updateAgent(props.data.id, request)
        useAlert('Berhasil disimpan')
    } finally {
        loadingSave.value = false
    }
}

const previewUrl = ref('https://ai.radyalabs.id/chatbot/e42c6098-d738-4161-9af2-5b6381ce3be0')
</script>