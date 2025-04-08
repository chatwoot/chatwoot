<template>
    <div>
        <form @submit.prevent="() => submit()">
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
</script>