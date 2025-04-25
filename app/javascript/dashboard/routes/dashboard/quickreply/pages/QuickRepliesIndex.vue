<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();

const quickReplies = ref([
  {
    id: 1,
    name: 'greeting',
    createdAt: '23 April 2025',
    content: 'hi welcome to the costumer AI service',
  },
]);

const searchTerm = ref('');
const filteredReplies = computed(() => {
  return quickReplies.value.filter(q =>
    q.name.toLowerCase().includes(searchTerm.value.toLowerCase())
  );
});

const handleEdit = id => {
  // route to the edit page (you can update this path as needed)
  router.push({ name: 'quickReplies_edit', params: { id } });
};

const handleDelete = id => {
  quickReplies.value = quickReplies.value.filter(q => q.id !== id);
};

const handleAddNew = () => {
  router.push({ name: 'quickReplies_add' });
};
</script>

<template>
  <div class="p-6 bg-white min-h-screen">
    <div class="flex justify-between items-center mb-6">
      <h2 class="text-xl font-semibold">Quick Replies</h2>
      <button
        @click="handleAddNew"
        class="bg-indigo-500 hover:bg-indigo-600 text-white px-4 py-2 rounded shadow"
      >
        Add Quick Reply
      </button>
    </div>

    <input
      v-model="searchTerm"
      placeholder="Search Quick Replies"
      class="border p-2 rounded w-full mb-4"
    />

    <div class="overflow-x-auto">
      <table class="min-w-full table-auto border-collapse">
        <thead>
          <tr class="bg-gray-100 text-left">
            <th class="p-2 border">Quick Reply Name</th>
            <th class="p-2 border">Created At</th>
            <th class="p-2 border">Content</th>
            <th class="p-2 border">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="reply in filteredReplies"
            :key="reply.id"
            class="hover:bg-gray-50"
          >
            <td class="p-2 border">{{ reply.name }}</td>
            <td class="p-2 border">{{ reply.createdAt }}</td>
            <td class="p-2 border">{{ reply.content }}</td>
            <td class="p-2 border space-x-2">
              <button
                @click="handleEdit(reply.id)"
                class="text-indigo-600 hover:underline"
              >
                Edit
              </button>
              <button
                @click="handleDelete(reply.id)"
                class="text-red-600 hover:underline"
              >
                Delete
              </button>
            </td>
          </tr>
        </tbody>
      </table>

      <div v-if="filteredReplies.length === 0" class="text-center py-6 text-gray-500">
        No quick replies found.
      </div>
    </div>
  </div>
</template>
