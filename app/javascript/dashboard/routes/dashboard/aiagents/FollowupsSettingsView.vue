<script setup>
import { ref, watch } from 'vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import CheckBox from 'v3/components/Form/CheckBox.vue';
import Icon from 'next/icon/Icon.vue';
import aiAgents from '../../../api/aiAgents';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  data: Object,
});

const followups = ref(
  props.data?.followups?.map(e => {
    return {
      ...createDefaultFollowup(),
      system_prompt: e.prompts,
      delay: e.delay,
      send_as_exact_message: e.send_as_exact_message,
      handoff_to_agent_after_sending: e.handoff_to_agent_after_sending,
    };
  }) || []
);
watch(
  () => props.data,
  v => {
    followups.value =
      v?.followups?.map(e => {
        return {
          ...createDefaultFollowup(),
          system_prompt: e.prompts,
          delay: e.delay,
          send_as_exact_message: e.send_as_exact_message,
          handoff_to_agent_after_sending: e.handoff_to_agent_after_sending,
        };
      }) || [];
  }
);

function createDefaultFollowup() {
  return {
    system_prompt: '',
    delay: 5,
    toggleOption: false,
    send_as_exact_message: false,
    handoff_to_agent_after_sending: false,
  };
}

function addFollowup() {
  followups.value.push(createDefaultFollowup());
}

const saveLoading = ref();
async function saveFollowups() {
  if (saveLoading.value) {
    return;
  }

  try {
    saveLoading.value = true;

    await aiAgents.updateAgentFollowups(
      props.data.id,
      followups.value?.map(e => {
        return {
          id: undefined,
          prompts: e.system_prompt,
          delay: e.delay,
          send_as_exact_message: e.send_as_exact_message,
          handoff_to_agent_after_sending: e.handoff_to_agent_after_sending,
        };
      }) || []
    );

    useAlert('Berhasil disimpan');
  } catch (e) {
    useAlert('Gagal simpan followups');
  } finally {
    saveLoading.value = false;
  }
}
</script>

<template>
  <div class="flex flex-col">
    <div class="flex flex-col text-sm">
      <span>
        Tentukan pesan tindak lanjut (Follow-up) yang akan dikirim ke pelanggan
        setelah jeda waktu tertentu.
      </span>
      <span>
        Lengkapi dengan prompt, yaitu instruksi bagi AI untuk menyusun pesan
        berdasarkan riwayat percakapan dan pengetahuan yang relevan.
      </span>
      <span>
        Anda juga dapat menyisipkan kondisi khusus untuk melakukan handoff ke
        agen manusia jika diperlukan, langsung di dalam prompt.
      </span>
    </div>
    <div class="mt-2 flex flex-col gap-3">
      <div
        v-for="(item, index) in followups"
        :key="index"
        class="flex flex-col bg-n-solid-1 px-5 pb-5 pt-3 rounded-lg"
      >
        <div>
          <label for="system_prompts">Prompt:</label>
          <TextArea
            id="system_prompts"
            v-model="item.system_prompt"
            custom-text-area-wrapper-class=""
            placeholder="Masukkan prompt di sini"
            custom-text-area-class="!outline-none"
            auto-height
          />
        </div>
        <div class="flex flex-row mt-2">
          <div class="flex-1 flex flex-row gap-2 self-start items-center">
            <span class="text-sm">Waktu jeda (menit):</span>
            <input
              v-model="item.delay"
              type="number"
              style="width: 75px; margin-bottom: 0px"
            />
          </div>
          <woot-button
            v-tooltip.top="$t('AGENT_MGMT.DELETE.BUTTON_TEXT')"
            variant="smooth"
            color-scheme="alert"
            icon="dismiss-circle"
            class-names="grey-btn"
            @click="
              () => {
                followups.splice(index, 1);
              }
            "
          />
        </div>
        <div>
          <div
            class="cursor-pointer flex flex-row gap-2 items-center px-2 py-1 mb-2"
            @click="() => (item.toggleOption = !item.toggleOption)"
          >
            <Icon
              :icon="
                item.toggleOption
                  ? 'i-lucide-chevron-right'
                  : 'i-lucide-chevron-down'
              "
              class="text-n-slate-11 size-4"
            />
            <label>Opsi tambahan:</label>
          </div>
          <div v-if="item.toggleOption" class="flex flex-col gap-2">
            <div class="flex flex-row gap-2">
              <CheckBox
                id="exact-message"
                :is-checked="item.send_as_exact_message"
                :value="item.send_as_exact_message"
                @update="
                  (_, value) => {
                    item.send_as_exact_message = value;
                  }
                "
              />
              <label
                class="text-sm font-normal text-ash-900"
                for="exact-message"
              >
                Kirim pesan sesuai dengan yang tertera
              </label>
            </div>
            <div class="flex flex-row gap-2">
              <CheckBox
                id="redirect-agent"
                :is-checked="item.handoff_to_agent_after_sending"
                :value="item.handoff_to_agent_after_sending"
                @update="
                  (_, value) => {
                    item.handoff_to_agent_after_sending = value;
                  }
                "
              />
              <label
                class="text-sm font-normal text-ash-900"
                for="redirect-agent"
              >
                Alihkan ke agen setelah pesan dikirim
              </label>
            </div>
          </div>
        </div>
      </div>
      <div class="flex flex-row gap-3 mt-2">
        <button
          class="button self-start"
          type="button"
          @click="() => saveFollowups()"
        >
          <span v-if="saveLoading" class="mt-4 mb-4 spinner" />
          <span v-else>Simpan</span>
        </button>
        <button
          class="button self-start clear"
          type="button"
          @click="addFollowup"
        >
          <span>Tambah</span>
        </button>
      </div>
    </div>
  </div>
</template>
