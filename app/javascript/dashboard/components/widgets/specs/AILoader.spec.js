import { mount } from '@vue/test-utils';
import { vi } from 'vitest';
import AILoader from '../AILoader.vue';

// Mock the $t function for translations
const $t = vi.fn(key => {
  const translations = {
    'INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.AI_WRITING':
      'AI is writing...',
  };
  return translations[key] || key;
});

const globalMocks = {
  $t,
};

describe('AILoader.vue', () => {
  let wrapper;

  afterEach(() => {
    if (wrapper) {
      wrapper.unmount();
    }
  });

  const createWrapper = (options = {}) => {
    return mount(AILoader, {
      global: {
        mocks: globalMocks,
        stubs: {
          'fluent-icon': {
            template:
              '<span class="fluent-icon" :class="$attrs.class" :data-icon="icon" :data-size="size"></span>',
            props: ['icon', 'size'],
          },
        },
      },
      ...options,
    });
  };

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders the loader container with correct structure', () => {
      expect(wrapper.find('.animation-container').exists()).toBe(true);
      expect(wrapper.find('.ai-typing--wrap').exists()).toBe(true);
    });

    it('renders the AI wand icon with correct props', () => {
      const icon = wrapper.find('.ai-typing--icon');

      expect(icon.exists()).toBe(true);
      expect(icon.attributes('data-icon')).toBe('wand');
      expect(icon.attributes('data-size')).toBe('14');
      expect(icon.classes()).toContain('ai-typing--icon');
    });

    it('displays the loading text', () => {
      const label = wrapper.find('label');

      expect(label.exists()).toBe(true);
      expect(label.text()).toBe('AI is writing...');
    });

    it('renders three animated loader dots', () => {
      const loaders = wrapper.findAll('.loader');

      expect(loaders).toHaveLength(3);

      loaders.forEach(loader => {
        expect(loader.exists()).toBe(true);
        expect(loader.element.tagName).toBe('SPAN');
      });
    });

    it('has correct CSS classes applied', () => {
      expect(wrapper.find('.animation-container').classes()).toContain(
        'margin-top-1'
      );
      expect(wrapper.find('.ai-typing--wrap').exists()).toBe(true);
      expect(wrapper.find('.ai-typing--icon').classes()).toContain(
        'ai-typing--icon'
      );
    });
  });

  describe('component structure', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('has the correct element hierarchy', () => {
      const container = wrapper.find('.animation-container');
      const aiWrap = container.find('.ai-typing--wrap');
      const icon = aiWrap.find('.ai-typing--icon');
      const label = aiWrap.find('label');
      const loaders = container.findAll('.loader');

      expect(container.exists()).toBe(true);
      expect(aiWrap.exists()).toBe(true);
      expect(icon.exists()).toBe(true);
      expect(label.exists()).toBe(true);
      expect(loaders).toHaveLength(3);
    });

    it('maintains proper DOM order', () => {
      const container = wrapper.find('.animation-container');
      const children = container.element.children;

      // First child should be the ai-typing--wrap
      expect(children[0].className).toContain('ai-typing--wrap');

      // Next three children should be loader spans
      expect(children[1].className).toContain('loader');
      expect(children[2].className).toContain('loader');
      expect(children[3].className).toContain('loader');
    });
  });

  describe('accessibility', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('provides semantic labeling for screen readers', () => {
      const label = wrapper.find('label');
      expect(label.exists()).toBe(true);
      expect(label.text()).toBeTruthy();
    });

    it('uses appropriate semantic elements', () => {
      // The component uses a label element for semantic meaning
      expect(wrapper.find('label').exists()).toBe(true);

      // Visual indicators are span elements with appropriate styling
      const loaders = wrapper.findAll('.loader');
      loaders.forEach(loader => {
        expect(loader.element.tagName).toBe('SPAN');
      });
    });
  });

  describe('styling and animation', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('applies correct CSS classes for styling', () => {
      expect(wrapper.find('.animation-container').exists()).toBe(true);
      expect(wrapper.find('.ai-typing--wrap').exists()).toBe(true);
      expect(wrapper.find('.ai-typing--icon').classes()).toContain(
        'ai-typing--icon'
      );
    });

    it('has loader elements with appropriate classes', () => {
      const loaders = wrapper.findAll('.loader');

      loaders.forEach(loader => {
        expect(loader.classes()).toContain('loader');
      });
    });
  });

  describe('translation integration', () => {
    it('calls translation function with correct key', () => {
      wrapper = createWrapper();

      expect($t).toHaveBeenCalledWith(
        'INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.AI_WRITING'
      );
    });

    it('displays translated text', () => {
      wrapper = createWrapper();
      const label = wrapper.find('label');

      expect(label.text()).toBe('AI is writing...');
    });

    it('handles missing translation gracefully', () => {
      const customT = vi.fn(key => key); // Return key if translation not found

      wrapper = mount(AILoader, {
        global: {
          mocks: { $t: customT },
          stubs: {
            'fluent-icon': {
              template: '<span class="fluent-icon"></span>',
            },
          },
        },
      });

      const label = wrapper.find('label');
      expect(label.text()).toBe(
        'INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.AI_WRITING'
      );
    });
  });

  describe('icon integration', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('passes correct props to fluent-icon component', () => {
      const icon = wrapper.find('.ai-typing--icon');

      expect(icon.attributes('data-icon')).toBe('wand');
      expect(icon.attributes('data-size')).toBe('14');
    });

    it('applies correct CSS class to icon', () => {
      const icon = wrapper.find('.ai-typing--icon');

      expect(icon.classes()).toContain('ai-typing--icon');
    });
  });

  describe('edge cases', () => {
    it('renders correctly without any props or data', () => {
      wrapper = createWrapper();

      expect(wrapper.exists()).toBe(true);
      expect(wrapper.find('.animation-container').exists()).toBe(true);
    });

    it('maintains structure with different global configurations', () => {
      wrapper = mount(AILoader, {
        global: {
          mocks: {
            $t: key => `Translated: ${key}`,
          },
          stubs: {
            'fluent-icon': true, // Stub with default template
          },
        },
      });

      expect(wrapper.find('.animation-container').exists()).toBe(true);
      expect(wrapper.find('label').text()).toContain('Translated:');
    });
  });

  describe('component lifecycle', () => {
    it('renders immediately without lifecycle hooks', () => {
      wrapper = createWrapper();

      // AILoader is a simple presentational component
      // It should render immediately without complex lifecycle logic
      expect(wrapper.find('.animation-container').exists()).toBe(true);
      expect(wrapper.find('label').exists()).toBe(true);
      expect(wrapper.findAll('.loader')).toHaveLength(3);
    });
  });
});
