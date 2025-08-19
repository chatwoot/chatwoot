import { ref, computed } from 'vue';

const mockResources = [
  {
    id: 1,
    title: 'Customer Service Guidelines',
    description:
      'Comprehensive guide on how to handle customer interactions and common scenarios.',
    category: 'Guidelines',
    createdAt: '2024-01-15',
    tags: ['customer-service', 'guidelines'],
  },
  {
    id: 2,
    title: 'Product Knowledge Base',
    description:
      'Detailed information about all our products, features, and pricing.',
    category: 'Documentation',
    createdAt: '2024-01-20',
    tags: ['product', 'features', 'pricing'],
  },
  {
    id: 3,
    title: 'Troubleshooting Common Issues',
    description:
      'Step-by-step solutions for the most frequently reported customer problems.',
    category: 'Troubleshooting',
    createdAt: '2024-01-25',
    tags: ['troubleshooting', 'support', 'issues'],
  },
  {
    id: 4,
    title: 'Sales Process Documentation',
    description:
      'Complete workflow for handling sales inquiries and closing deals.',
    category: 'Sales',
    createdAt: '2024-01-30',
    tags: ['sales', 'process', 'workflow'],
  },
  {
    id: 5,
    title: 'Team Communication Standards',
    description: 'Best practices for internal communication and collaboration.',
    category: 'Internal',
    createdAt: '2024-02-05',
    tags: ['communication', 'team', 'standards'],
  },
  {
    id: 6,
    title: 'Escalation Procedures',
    description: 'When and how to escalate issues to managers or specialists.',
    category: 'Procedures',
    createdAt: '2024-02-10',
    tags: ['escalation', 'procedures', 'management'],
  },
];

export function useLibraryResources() {
  const resources = ref([...mockResources]);
  const searchQuery = ref('');
  const currentPage = ref(1);
  const itemsPerPage = ref(10);
  const isLoading = ref(false);

  const filteredResources = computed(() => {
    if (!searchQuery.value) return resources.value;

    const query = searchQuery.value.toLowerCase();
    return resources.value.filter(
      resource =>
        resource.title.toLowerCase().includes(query) ||
        resource.description.toLowerCase().includes(query) ||
        resource.category.toLowerCase().includes(query) ||
        resource.tags.some(tag => tag.toLowerCase().includes(query))
    );
  });

  const paginatedResources = computed(() => {
    const start = (currentPage.value - 1) * itemsPerPage.value;
    const end = start + itemsPerPage.value;
    return filteredResources.value.slice(start, end);
  });

  const totalItems = computed(() => filteredResources.value.length);
  const totalPages = computed(() =>
    Math.ceil(totalItems.value / itemsPerPage.value)
  );

  const searchResources = query => {
    searchQuery.value = query;
    currentPage.value = 1;
  };

  const updateCurrentPage = page => {
    currentPage.value = page;
  };

  const getResourceById = id => {
    return resources.value.find(resource => resource.id === id);
  };

  return {
    resources: paginatedResources,
    searchQuery,
    currentPage,
    totalItems,
    totalPages,
    isLoading,
    searchResources,
    updateCurrentPage,
    getResourceById,
  };
}
