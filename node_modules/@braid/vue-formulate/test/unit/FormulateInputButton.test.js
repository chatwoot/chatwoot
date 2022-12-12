import Vue from 'vue'
import flushPromises from 'flush-promises'
import { mount, createLocalVue } from '@vue/test-utils'
import Formulate from '@/Formulate.js'
import FormulateInput from '@/FormulateInput.vue'
import FormulateInputButton from '@/inputs/FormulateInputButton.vue'

Vue.use(Formulate)

describe('FormulateInputButton', () => {

  it('renders a button element', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'button' } })
    expect(wrapper.findComponent(FormulateInputButton).exists()).toBe(true)
  })

  it('renders a button element when type submit', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'submit' } })
    expect(wrapper.findComponent(FormulateInputButton).exists()).toBe(true)
  })

  it('uses value as highest priority content', () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'submit',
      value: 'Value content',
      label: 'Label content',
      name: 'Name content'
    }})
    expect(wrapper.find('button').text()).toBe('Value content')
  })

  it('uses label as second highest priority content', () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'submit',
      label: 'Label content',
      name: 'Name content'
    }})
    expect(wrapper.find('button').text()).toBe('Label content')
  })

  it('uses name as lowest priority content', () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'submit',
      name: 'Name content'
    }})
    expect(wrapper.find('button').text()).toBe('Name content')
  })

  it('uses "Submit" as default content', () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'submit',
    }})
    expect(wrapper.find('button').text()).toBe('Submit')
  })

  it('with label does not render label element', () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'button',
      label: 'my label'
    }})
    expect(wrapper.find('label').exists()).toBe(false)
  })

  it('does not render label element when type "submit"', () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'button',
      label: 'my label'
    }})
    expect(wrapper.find('label').exists()).toBe(false)
  })

  it('renders slot inside button when type "button"', () => {
    const wrapper = mount(FormulateInput, {
      propsData: {
        type: 'button',
        label: 'my label',
      },
      slots: {
        default: '<span>My custom slot</span>'
      }
    })
    expect(wrapper.find('button > span').html()).toBe('<span>My custom slot</span>')
  })

  it('emits a click event when the button itself is clicked', async () => {
    const handle = jest.fn();
    const wrapper = mount({
      template: `
        <div>
          <FormulateInput
            type="submit"
            @click="handle"
          />
        </div>
      `,
      methods: {
        handle
      }
    })
    wrapper.find('button[type="submit"]').trigger('click')
    await flushPromises();
    expect(handle.mock.calls.length).toBe(1)
  })

  it('passes an explicitly given name prop through to the root element', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'button', name: 'foo' } })
    expect(wrapper.find('button[name="foo"]').exists()).toBe(true)
  })

  it('additional context does not bleed through to button input attributes', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'button' } } )
    expect(Object.keys(wrapper.find('button').attributes())).toEqual(["type", "id"])
  })

  it('can add classes to the element wrapper', () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'button', elementClass: ['test-class']}
    })
    expect(wrapper.findComponent(FormulateInputButton).attributes('class'))
      .toBe('formulate-input-element formulate-input-element--button test-class')
  })

  it('can add classes to the input element', () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'submit', inputClass: ['test-class']}
    })
    expect(wrapper.find('button').attributes('class'))
      .toBe('test-class')
  })

  it('emits a focus event', async () => {
    const focus = jest.fn()
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'button', label: 'Submit me' },
      listeners: { focus }
    })
    wrapper.find('button').trigger('focus')
    await flushPromises()
    expect(focus.mock.calls.length).toBe(1);
  })

  it('allows slot injection of of a prefix and suffix', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          type="button"
          label="money"
        >
          <template #prefix="{ label }">
            <span>\${{ label }}</span>
          </template>
          <template #suffix="{ label }">
            <span>after {{ label }}</span>
          </template>
        </FormulateInput>
      `
    })
    expect(wrapper.find('.formulate-input-element > span').text()).toBe('$money')
    expect(wrapper.find('.formulate-input-element > *:last-child').text()).toBe('after money')
  })

  // Note, this should be the last test
  it('renders the slotComponent buttonContent', async () => {
    const localVue = createLocalVue()
    localVue.component('CustomButtonContent', {
      render: function (h) {
        return h('div', { class: 'custom-button-content' }, this.context.label)
      },
      props: ['context']
    })
    localVue.use(Formulate, { slotComponents: { buttonContent: 'CustomButtonContent' } })
    const wrapper = mount(FormulateInput, { localVue, propsData: { type: 'button', label: 'My button yall!' } })
    expect(wrapper.find('.custom-button-content').text()).toBe('My button yall!')
  })
})

