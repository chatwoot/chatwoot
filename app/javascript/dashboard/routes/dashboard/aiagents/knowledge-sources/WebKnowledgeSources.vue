<template>
    <div class="flex flex-col justify-stretch gap-4">
        <div class="text-center" v-if="isFetching">
            <span class="mt-4 mb-4 spinner" />
        </div>

        <div>
            <span class="text-xl font-bold">
                Tambahkan Link
            </span>
            <div class="py-2">

            </div>
        </div>

        <div>
            <span class="text-xl font-bold">
                Trained Links
            </span>
            <div class="flex flex-row gap-2 items-center mt-2">
                <div class="py-4 pr-2 flex flex-row gap-4 items-center">
                    <CheckBox id="select-all" :is-checked="isAllSelected" :value="isAllSelected" @update="(_, value) => {
                        selectAll(value)
                    }" />
                    <label for="select-all">
                        Pilih semua
                    </label>
                </div>
                <Button variant="ghost" icon="i-lucide-trash" size="sm" color="ruby" v-if="hasSelectedLink" @click="() => {
                    showDeleteModal = true
                }" :is-loading="isDeleting">
                    Hapus
                </Button>
                <Input class="flex-1" placeholder="Cari links" v-model="searchLink" />
            </div>
            <div class="py-2 flex flex-row gap-4" v-for="(item, index) in groupedLinks" :key="index">
                <div class="py-4">
                    <CheckBox :is-checked="isChildrenAllLinksSelected(item[1])"
                        :value="isChildrenAllLinksSelected(item[1])" @update="(_, value) => {
                            item[1].forEach(v => {
                                v.isSelected.value = value
                            })
                        }" />
                </div>
                <div class="py-2 flex-1 min-w-0">
                    <div class="flex flex-col gap-2 border border-n-gray-5 rounded-lg">
                        <div class="flex flex-row gap-2 items-center py-2 px-4">
                            <div class="flex-1">
                                <a :href="item[1][0].parent_url" target="_blank" class="hover:underline">
                                    <span class="text-base">{{ item[1][0].parent_url }}</span>
                                </a>
                            </div>
                            <div class="flex flex-row gap-3 items-center">
                                <div class="rounded-lg bg-n-gray-4 text-sm px-2 py-1">
                                    <span class="font-bold">
                                        {{item[1].reduce((p, i) => p + i.total_chars, 0)}}
                                    </span>
                                    <span>
                                        karakter
                                    </span>
                                </div>
                                <div class="rounded-lg bg-n-gray-4 text-sm px-2 py-1 cursor-pointer flex flex-row items-center gap-1"
                                    @click="() => {
                                        toggleLinks[index] = !toggleLinks[index]
                                    }">
                                    <span class="font-bold">
                                        {{ item[1].length }}
                                    </span>
                                    <span>
                                        links
                                    </span>
                                    <span :class="toggleLinks[index] ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
                                        class="size-5" aria-hidden="true" />
                                </div>
                            </div>
                        </div>
                        <div class="flex flex-col px-4 gap-3 pb-4" v-if="toggleLinks[index]">
                            <span class="text-sm font-bold">
                                Links
                            </span>
                            <div v-for="(item, index) in item[1]" :key="index" class="flex flex-row gap-2">
                                <div class="flex-1 flex flex-row gap-4 items-center">
                                    <CheckBox :is-checked="item.isSelected.value" :value="item.isSelected.value"
                                        @update="(_, value) => {
                                            item.isSelected.value = value
                                        }" />
                                    <div class="bg-n-gray-4 px-4 py-1 cursor-pointer" @click="() => {
                                        item.isSelected.value = item.isSelected.value ? false : true
                                    }">
                                        <a :href="item.url" target="_blank" class="hover:underline">
                                            <span class="text-base">{{ item.url }}</span>
                                        </a>
                                    </div>
                                </div>
                                <Button variant="ghost" icon="i-lucide-pencil" size="sm">
                                    Ubah
                                </Button>
                                <div class="bg-n-gray-4 text-sm px-2 py-1 flex flex-row gap-1 items-center">
                                    <span class="font-bold">
                                        {{ item.total_chars }}
                                    </span>
                                    <span>
                                        karakter
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <woot-delete-modal v-if="showDeleteModal" v-model:show="showDeleteModal" class="context-menu--delete-modal"
            :on-close="() => {
                showDeleteModal = false
            }" :on-confirm="() => deleteData()" :title="'Apakah kamu akan menghapus data ini?'"
            :message="'Kamu tidak akan mengembalikan data ini'"
            :confirm-text="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.DELETE')"
            :reject-text="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.CANCEL')" />
    </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import aiAgents from '../../../../api/aiAgents';
import { useAlert } from 'dashboard/composables';
import CheckBox from 'v3/components/Form/CheckBox.vue';

const props = defineProps({
    data: {
        type: Object,
        required: true,
    },
})

const searchLink = ref('')

function groupBy(list, keyGetter) {
    const map = new Map();
    list.forEach((item) => {
        const key = keyGetter(item);
        const collection = map.get(key);
        if (!collection) {
            map.set(key, [item]);
        } else {
            collection.push(item);
        }
    });
    return map;
}

const toggleLinks = ref({})
const links = ref([])
const mappedLinks = computed(() => {
    return links.value.map(e => ({
        ...e,
        isSelected: ref(false),
    }))
})
const filteredLinks = computed(() => {
    return mappedLinks.value.filter(v => v.parent_url.includes(searchLink.value.trim()))
})
const groupedLinks = computed(() => {
    return groupBy(filteredLinks.value, v => v.knowledge_source_id)
})
function selectAll(value) {
    mappedLinks.value.forEach(t => {
        t.isSelected.value = value
    })
}
const isAllSelected = computed(() => {
    return mappedLinks.value.every(t => t.isSelected.value)
})
const hasSelectedLink = computed(() => {
    return mappedLinks.value.some(t => t.isSelected.value)
})
watch(groupedLinks, v => {
    toggleLinks.value = {}
})
const isFetching = ref(false)
async function fetchKnowledge() {
    try {
        isFetching.value = true
        const data = await aiAgents.getKnowledgeSources(props.data.id)
        links.value = (data.data?.knowledge_source_websites || [])
    } catch (e) {
        useAlert('Gagal mendapatkan dapat')
    } finally {
        isFetching.value = false
    }
}

watch(() => props.data, v => {
    if (!v) {
        return
    }
    fetchKnowledge()
}, {
    immediate: true,
    deep: true,
})

const showDeleteModal = ref()
const isDeleting = ref(false)
async function deleteData() {
    try {
        const selectedIds = mappedLinks.value.filter((t) => t.isSelected.value).map(t => t.id)
        if (!selectedIds.length) {
            return
        }

        showDeleteModal.value = false
        isDeleting.value = true

        await aiAgents.deleteKnowledgeWebsite(props.data.id, {
            ids: selectedIds,
        })

        fetchKnowledge()
        useAlert('Berhasil hapus data')
    } catch (e) {
        useAlert('Gagal hapus data')
    } finally {
        isDeleting.value = false
    }
}

const newFiles = ref([])
function openPicker() {
    const inputFile = document.getElementById('inputfile')
    inputFile.click()
}
function addFile(files) {
    newFiles.value.push(files.target.files[0])
}

const isSaving = ref(false)
async function save() {
    if (!newFiles.value.length) {
        return
    }

    try {
        isSaving.value = true

        const formData = new FormData()
        for (const element of newFiles.value) {
            formData.append('file', element)
        }

        await aiAgents.addKnowledgeFile(props.data.id, formData)
        newFiles.value = []
        fetchKnowledge()
        useAlert('Berhasil simpan data')
    } catch (e) {
        useAlert("Gagal simpan data")
    } finally {
        isSaving.value = false
    }
}

function isChildrenAllLinksSelected(links) {
    return links.every(t => t.isSelected.value ? true : false)
}
</script>

<style lang="css">
.note-editing-area {
    background: white;
}
</style>