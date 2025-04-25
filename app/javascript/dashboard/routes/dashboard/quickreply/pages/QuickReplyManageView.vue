<template>
  <div class="relative bg-white min-h-screen w-full h-full">
    <div class="flex flex-col gap-4 w-full h-full px-6 py-4">
      <!-- Header -->
      <div class="flex items-center justify-between px-6 pt-6">
        <h1 class="text-2xl font-bold">Quick Replies</h1>
        <div class="flex items-center gap-2">
          <button
            class="bg-indigo-500 text-white px-4 py-[9px] rounded hover:bg-indigo-600 whitespace-nowrap text-sm"
            @click="showModal = true"
          >
            Add Quick Reply
          </button>
          <input
            v-model="search"
            type="text"
            placeholder="Search Quick Replies"
            class="px-4 py-[9px] border rounded-md focus:outline-none text-sm"
          />
        </div>
      </div>



      <!-- Table -->
      <div class="overflow-x-auto bg-white rounded-lg shadow w-full">
        <table class="min-w-full text-left border-separate border-spacing-y-2">
          <thead>
            <tr class="text-gray-600 text-sm">
              <th class="px-4 py-2">Quick Reply Name</th>
              <th class="px-4 py-2">Created At</th>
              <th class="px-4 py-2">Content</th>
              <th class="px-4 py-2">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="reply in filteredReplies"
              :key="reply.id"
              class="bg-gray-50 rounded-md"
            >
              <td class="px-4 py-2">{{ reply.name }}</td>
              <td class="px-4 py-2">{{ formatDate(reply.createdAt) }}</td>
              <td class="px-4 py-2">{{ reply.content }}</td>
              <td class="px-4 py-2 space-x-2">
                <button class="px-3 py-1 border text-indigo-600 border-indigo-600 rounded hover:bg-indigo-50">
                  Edit
                </button>
                <button class="px-3 py-1 border text-red-600 border-red-600 rounded hover:bg-red-50">
                  Delete
                </button>
              </td>
            </tr>
            <tr v-if="filteredReplies.length === 0">
              <td colspan="4" class="text-center text-gray-500 py-4">
                No Quick Replies found.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <QuickReplyModal :show="showModal" @close="showModal = false" />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import QuickReplyModal from './QuickReplyModal.vue'

const showModal = ref(false)

const search = ref('');

const replies = ref([
  {
    id: 1,
    name: 'greeting',
    createdAt: '2025-04-23',
    content: 'hi welcome to the costumer AI service',
  },
]);

const filteredReplies = computed(() => {
  if (!search.value.trim()) return replies.value;
  return replies.value.filter(reply =>
    reply.name.toLowerCase().includes(search.value.toLowerCase())
  );
});

const formatDate = dateStr => {
  const date = new Date(dateStr);
  return new Intl.DateTimeFormat('en-GB', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
  }).format(date);
};
</script>
