// Mock API for Library Resources - TODO: Replace with real API when backend is ready

const mockData = [
  {
    id: 1,
    title: 'Customer Service Guidelines',
    description:
      'Comprehensive guide on how to handle customer interactions and common scenarios.',
    content: 'This is the full content of customer service guidelines...',
    created_at: '2024-01-15T00:00:00Z',
  },
  {
    id: 2,
    title: 'Product Knowledge Base',
    description:
      'Detailed information about all our products, features, and pricing.',
    content: 'This is the full content of product knowledge base...',
    created_at: '2024-01-20T00:00:00Z',
  },
  {
    id: 3,
    title: 'Troubleshooting Common Issues',
    description:
      'Step-by-step solutions for the most frequently reported customer problems.',
    content: 'This is the full content of troubleshooting guide...',
    created_at: '2024-01-25T00:00:00Z',
  },
  {
    id: 4,
    title: 'Sales Process Documentation',
    description:
      'Complete workflow for handling sales inquiries and closing deals.',
    content: 'This is the full content of sales process documentation...',
    created_at: '2024-01-30T00:00:00Z',
  },
  {
    id: 5,
    title: 'Team Communication Standards',
    description: 'Best practices for internal communication and collaboration.',
    content: 'This is the full content of communication standards...',
    created_at: '2024-02-05T00:00:00Z',
  },
  {
    id: 6,
    title: 'Escalation Procedures',
    description: 'When and how to escalate issues to managers or specialists.',
    content: 'This is the full content of escalation procedures...',
    created_at: '2024-02-10T00:00:00Z',
  },
];

let mockStorage = [...mockData];

class LibraryResourcesAPI {
  constructor() {
    this.delay = 300; // Simulate network delay
  }

  async get() {
    return new Promise(resolve => {
      setTimeout(() => {
        resolve({
          data: {
            payload: mockStorage,
            meta: {
              count: mockStorage.length,
              current_page: 1,
            },
          },
        });
      }, this.delay);
    });
  }

  async show(id) {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        const resource = mockStorage.find(item => item.id === parseInt(id, 10));
        if (!resource) {
          reject(new Error('Resource not found'));
          return;
        }
        resolve({
          data: {
            payload: resource,
          },
        });
      }, this.delay);
    });
  }

  async create(resourceData) {
    return new Promise(resolve => {
      setTimeout(() => {
        const newId = Math.max(...mockStorage.map(r => r.id)) + 1;
        const newResource = {
          id: newId,
          ...resourceData,
          created_at: new Date().toISOString(),
        };
        mockStorage.push(newResource);
        resolve({
          data: {
            payload: newResource,
          },
        });
      }, this.delay);
    });
  }

  async update(id, resourceData) {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        const index = mockStorage.findIndex(
          item => item.id === parseInt(id, 10)
        );
        if (index === -1) {
          reject(new Error('Resource not found'));
          return;
        }
        mockStorage[index] = {
          ...mockStorage[index],
          ...resourceData,
        };
        resolve({
          data: {
            payload: mockStorage[index],
          },
        });
      }, this.delay);
    });
  }

  async delete(id) {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        const index = mockStorage.findIndex(
          item => item.id === parseInt(id, 10)
        );
        if (index === -1) {
          reject(new Error('Resource not found'));
          return;
        }
        mockStorage.splice(index, 1);
        resolve({
          data: {
            payload: { success: true },
          },
        });
      }, this.delay);
    });
  }
}

export default new LibraryResourcesAPI();
