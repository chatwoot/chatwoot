import Vue from 'vue'
import { mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import Formulate from '@/Formulate.js'
import FileUpload from '@/FileUpload.js'
import FormulateInput from '@/FormulateInput.vue'
import FormulateForm from '@/FormulateForm.vue'
import FormulateGrouping from '@/FormulateGrouping.vue'
import FormulateRepeatableRemove from '@/slots/FormulateRepeatableRemove.vue'
import FormulateRepeatableProvider from '@/FormulateRepeatableProvider.vue'

Vue.use(Formulate)

describe('FormulateInputGroup', () => {
  it('allows nested fields to be sub-rendered', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'group' },
      slots: {
        default: '<FormulateInput type="text" />'
      }
    })
    expect(wrapper.findAll('.formulate-input-group-repeatable input[type="text"]').length).toBe(1)
  })

  it('registers sub-fields with grouping', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'group' },
      slots: {
        default: '<FormulateInput type="text" name="persona" />'
      }
    })
    expect(wrapper.findComponent(FormulateRepeatableProvider).vm.registry.has('persona')).toBeTruthy()
  })

  it('is not repeatable by default', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'group' },
      slots: {
        default: '<FormulateInput type="text" />'
      }
    })
    expect(wrapper.findAll('.formulate-input-group-add-more').length).toBe(0)
  })

  it('adds an add more button when repeatable', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'group', repeatable: true },
      slots: {
        default: '<FormulateInput type="text" />'
      }
    })
    expect(wrapper.findAll('.formulate-input-group-add-more').length).toBe(1)
  })

  it('repeats the default slot when adding more', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'group', repeatable: true },
      slots: {
        default: '<div class="wrap"><FormulateInput type="text" /></div>'
      }
    })
    wrapper.find('.formulate-input-group-add-more button').trigger('click')
    await flushPromises();
    expect(wrapper.findAll('.wrap').length).toBe(2)
  })

  it('re-hydrates a repeatable field', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'group', repeatable: true, value: [{email: 'jon@example.com'}, {email:'jane@example.com'}] },
      slots: {
        default: '<div class="wrap"><FormulateInput type="text" name="email" /></div>'
      }
    })
    await flushPromises()
    const fields = wrapper.findAll('input[type="text"]')
    expect(fields.length).toBe(2)
    expect(fields.at(0).element.value).toBe('jon@example.com')
    expect(fields.at(1).element.value).toBe('jane@example.com')
  })

  it('v-modeling a subfield changes all values', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          v-model="users"
          type="group"
        >
          <FormulateInput type="text" v-model="email" name="email" />
          <FormulateInput type="text" name="name" />
        </FormulateInput>
      `,
      data () {
        return {
          users: [{email: 'jon@example.com'}, {email:'jane@example.com'}],
          email: 'jim@example.com'
        }
      }
    })
    await flushPromises()
    const fields = wrapper.findAll('input[type="text"]')
    expect(fields.length).toBe(4)
    expect(fields.at(2).element.value).toBe('jim@example.com')
  })

  /**
   * As of 2.5.0 v-modeling a child of a group and a parent of that group at
   * the same time is no longer strictly supported. Technically it should still
   * work after the initial load, but never-used "feature" is a casualty of
   * fixing other group issues.
   */
  it('v-modeling a subfield updates group v-model value', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          v-model="users"
          type="group"
        >
          <FormulateInput type="text" v-model="email" name="email" />
          <FormulateInput type="text" name="name" />
        </FormulateInput>
      `,
      data () {
        return {
          users: [{email: 'jon@example.com'}, {email:'jane@example.com'}],
          email: 'jim@example.com'
        }
      }
    })
    await flushPromises()
    expect(wrapper.vm.users).toEqual([{email: 'jim@example.com'}, {email:'jim@example.com'}])
  })

  it('Can sync values across two different groups', async () => {
      const wrapper = mount({
        template: `
          <div>
            <FormulateInput
              v-model="names"
              type="group"
            >
              <FormulateInput
                type="text"
                name="name"
              />
            </FormulateInput>
            <FormulateInput
              v-model="names"
              type="group"
            >
              <FormulateInput
                type="text"
                name="name"
              />
            </FormulateInput>
          </div>
        `,
        data () {
          return {
            names: [{ name: 'Justin' }]
          }
        }
      })
      await flushPromises()
      wrapper.find('input').setValue('Tom')
      await flushPromises()
      expect(wrapper.findAll('input').wrappers.map(input => input.element.value)).toEqual(['Tom', 'Tom'])
  })

  it('prevents form submission when children have validation errors', async () => {
    const submit = jest.fn()
    const wrapper = mount({
      template: `
        <FormulateForm
          @submit="submit"
        >
          <FormulateInput
            type="text"
            validation="required"
            value="testing123"
            name="name"
          />
          <FormulateInput
            v-model="users"
            type="group"
          >
            <FormulateInput type="text" name="email" />
            <FormulateInput type="text" name="name" validation="required" />
          </FormulateInput>
          <FormulateInput type="submit" />
        </FormulateForm>
      `,
      data () {
        return {
          users: [{email: 'jon@example.com'}, {email:'jane@example.com'}],
        }
      },
      methods: {
        submit
      }
    })
    const form = wrapper.findComponent(FormulateForm)
    await form.vm.formSubmitted()
    expect(submit.mock.calls.length).toBe(0);
  })

  it('allows form submission with children when there are no validation errors', async () => {
    const submit = jest.fn()
    const wrapper = mount({
      template: `
        <FormulateForm
          @submit="submit"
        >
          <FormulateInput
            type="text"
            validation="required"
            value="testing123"
            name="name"
          />
          <FormulateInput
            name="users"
            type="group"
          >
            <FormulateInput type="text" name="email" validation="required|email" value="justin@wearebraid.com" />
            <FormulateInput type="text" name="name" validation="required" value="party" />
          </FormulateInput>
          <FormulateInput type="submit" />
        </FormulateForm>
      `,
      methods: {
        submit
      }
    })
    const form = wrapper.findComponent(FormulateForm)
    await form.vm.formSubmitted()
    expect(submit.mock.calls.length).toBe(1);
  })

  it('displays validation errors on group children when form is submitted', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm>
          <FormulateInput
            name="users"
            type="group"
            :repeatable="true"
          >
            <FormulateInput type="text" name="name" validation="required" />
          </FormulateInput>
          <FormulateInput type="submit" />
        </FormulateForm>
      `
    })
    const form = wrapper.findComponent(FormulateForm)
    await form.vm.formSubmitted()
    await flushPromises()
    expect(wrapper.find('[data-classification="text"] .formulate-input-error').exists()).toBe(true);
  })

  it('displays error messages on newly registered fields when formShouldShowErrors is true', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm>
          <FormulateInput
            name="users"
            type="group"
            :repeatable="true"
          >
            <FormulateInput type="text" name="name" validation="required" />
          </FormulateInput>
          <FormulateInput type="submit" />
        </FormulateForm>
      `
    })
    const form = wrapper.findComponent(FormulateForm)
    await form.vm.formSubmitted()
    // Click the add more button
    wrapper.find('button[type="button"]').trigger('click')
    await flushPromises()
    expect(wrapper.findAll('[data-classification="text"] .formulate-input-error').length).toBe(2)
  })

  it('displays error messages on newly registered fields when formShouldShowErrors is true', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm>
          <FormulateInput
            name="users"
            type="group"
            :repeatable="true"
          >
            <FormulateInput type="text" name="name" validation="required" />
          </FormulateInput>
          <FormulateInput type="submit" />
        </FormulateForm>
      `
    })
    const form = wrapper.findComponent(FormulateForm)
    await form.vm.formSubmitted()
    // Click the add more button
    wrapper.find('button[type="button"]').trigger('click')
    await flushPromises()
    expect(wrapper.findAll('[data-classification="text"] .formulate-input-error').length).toBe(2)
  })

  it('allows the removal of groups', async () => {
    const wrapper = mount({
      template: `
      <FormulateForm>
        <FormulateInput
          name="users"
          type="group"
          :repeatable="true"
          v-model="users"
        >
          <FormulateInput type="text" name="name" validation="required" />
        </FormulateInput>
        <FormulateInput type="submit" />
      </FormulateForm>
      `,
      data () {
        return {
          users: [{name: 'justin'}, {name: 'bill'}]
        }
      }
    })
    await flushPromises()
    wrapper.find('.formulate-input-group-repeatable-remove').trigger('click')
    await flushPromises()
    expect(wrapper.vm.users).toEqual([{name: 'bill'}])
  })

  it('removes groups when there are none', async () => {
    const wrapper = mount({
      template: `
      <FormulateForm>
        <FormulateInput
          name="users"
          type="group"
          :repeatable="true"
          v-model="users"
        >
          <FormulateInput type="text" name="name" validation="required" />
        </FormulateInput>
        <FormulateInput type="submit" />
      </FormulateForm>
      `,
      data () {
        return {
          users: undefined
        }
      }
    })
    expect(wrapper.find('input[type="text"]').exists()).toBe(true)
    await flushPromises()
    wrapper.find('.formulate-input-group-repeatable-remove').trigger('click')
    await flushPromises()
    expect(wrapper.find('input[type="text"]').exists()).toBe(false)
  })

  it('fills to minimum and will not remove when at its minimum', async () => {
    const wrapper = mount({
      template: `
      <FormulateForm>
        <FormulateInput
          name="users"
          type="group"
          :repeatable="true"
          minimum="3"
          v-model="users"
        >
          <FormulateInput type="text" name="name" validation="required" />
        </FormulateInput>
        <FormulateInput type="submit" />
      </FormulateForm>
      `,
      data () {
        return {
          users: undefined
        }
      }
    })
    expect(wrapper.findAll('input[type="text"]').length).toBe(3)
    await flushPromises()
    wrapper.find('.formulate-input-group-repeatable-remove').trigger('click')
    await flushPromises()
    expect(wrapper.findAll('input[type="text"]').length).toBe(3)
  })

  it('can override the add more text', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { addLabel: '+ Add a user', type: 'group', repeatable: true },
      slots: {
        default: '<div />'
      }
    })
    expect(wrapper.find('button').text()).toEqual('+ Add a user')
  })

  it('does not allow more than the limit', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { addLabel: '+ Add a user', type: 'group', repeatable: true, limit: 2, value: [{}, {}]},
      slots: {
        default: '<div class="repeated"/>'
      }
    })
    expect(wrapper.findAll('.repeated').length).toBe(2)
    expect(wrapper.find('button').exists()).toBeFalsy()
  })

  it('does not truncate the number of items if value is more than limit', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { addLabel: '+ Add a user', type: 'group', repeatable: true, limit: 2, value: [{}, {}, {}, {}]},
      slots: {
        default: '<div class="repeated"/>'
      }
    })
    expect(wrapper.findAll('.repeated').length).toBe(4)
  })

  it('allows a slot override of the add button and has addItem prop', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'group', repeatable: true, addLabel: '+ Name' },
      scopedSlots: {
        default: '<div class="repeatable" />',
        addmore: '<span class="add-name" @click="props.addMore">{{ props.addLabel }}</span>'
      }
    })
    expect(wrapper.find('.formulate-input-group-add-more').exists()).toBeFalsy()
    const addButton = wrapper.find('.add-name')
    expect(addButton.text()).toBe('+ Name')
    addButton.trigger('click')
    await flushPromises()
    expect(wrapper.findAll('.repeatable').length).toBe(2)
  })

  it('allows a slot override of the repeatable area', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'group', repeatable: true, value: [{}, {}]},
      scopedSlots: {
        repeatable: '<div class="repeat">{{ props.index }}<div class="remove" @click="props.removeItem" /></div>',
      }
    })
    const repeats = wrapper.findAll('.repeat')
    expect(repeats.length).toBe(2)
    expect(repeats.at(1).text()).toBe("1")
    wrapper.find('.remove').trigger('click')
    await flushPromises()
    expect(wrapper.findAll('.repeat').length).toBe(1)
  })

  it('allows a slot override of the remove area', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'group', repeatable: true, value: [{phone: 'iPhone'}, {phone: 'Android'}]},
      scopedSlots: {
        default: '<FormulateInput type="text" name="phone" />',
        remove: '<button @click="props.removeItem" class="remove-this">Get outta here</button>',
      }
    })
    const repeats = wrapper.findAll('.remove-this')
    expect(repeats.length).toBe(2)
    const button = wrapper.find('.remove-this')
    expect(button.text()).toBe('Get outta here')
    button.trigger('click')
    await flushPromises()
    expect(wrapper.findAll('input').wrappers.map(w => w.element.value)).toEqual(['Android'])
  })

  it('removes the proper item from the group', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'group', repeatable: true },
      slots: {
        default: '<FormulateInput type="text" name="foo" />'
      }
    })
    wrapper.find('input').setValue('first entry')
    wrapper.find('.formulate-input-group-add-more button').trigger('click')
    wrapper.find('.formulate-input-group-add-more button').trigger('click')
    await flushPromises();
    wrapper.findAll('input').at(1).setValue('second entry')
    wrapper.findAll('input').at(2).setValue('third entry')
    // First verify all the proper entries are where we expect
    expect(wrapper.findAll('input').wrappers.map(input => input.element.value)).toEqual(['first entry', 'second entry', 'third entry'])
    // Now remove the middle one
    wrapper.findAll('.formulate-input-group-repeatable-remove').at(1).trigger('click')
    await flushPromises()
    expect(wrapper.findAll('input').wrappers.map(input => input.element.value)).toEqual(['first entry', 'third entry'])
  })

  it('can override the remove text', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { removeLabel: 'Delete this', type: 'group', repeatable: true },
      slots: {
        default: '<div />'
      }
    })
    expect(wrapper.find('a').text()).toEqual('Delete this')
  })

  it('does not show an error message on group input when child has an error', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm>
          <FormulateInput
            type="text"
            validation="required"
            value="testing123"
            name="name"
          />
          <FormulateInput
            v-model="users"
            type="group"
          >
            <FormulateInput type="text" name="email" />
            <FormulateInput type="text" name="name" validation="required" />
          </FormulateInput>
          <FormulateInput type="submit" />
        </FormulateForm>
      `,
      data () {
        return {
          users: [{email: 'jon@example.com'}, {}],
        }
      }
    })
    const form = wrapper.findComponent(FormulateForm)
    await form.vm.formSubmitted()
    expect(wrapper.find('[data-classification="group"] > .formulate-input-errors').exists()).toBe(false)
  })

  it('exposes the index to the context object on default slot', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          type="group"
          name="test"
          #default="{ name, index }"
          :value="[{}, {}]"
        >
          <div class="repeatable">{{ name }}-{{ index }}</div>
        </FormulateInput>
      `,
    })
    const repeatables = wrapper.findAll('.repeatable')
    expect(repeatables.length).toBe(2)
    expect(repeatables.at(0).text()).toBe('test-0')
    expect(repeatables.at(1).text()).toBe('test-1')
  })

  it('exposes the index to the remove slot', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          type="group"
          name="test"
          :value="[{}, {}]"
        >
        </FormulateInput>
      `,
    })
    const removes = wrapper.findAllComponents(FormulateRepeatableRemove)
    expect(removes.at(0).vm.index).toBe(0)
    expect(removes.at(1).vm.index).toBe(1)
  })

  it('forces non-repeatable groups to not initialize with an empty array', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          type="group"
          name="test"
          v-model="model"
        >
          <div class="repeatable" />
        </FormulateInput>
      `,
      data () {
        return {
          model: []
        }
      }
    })
    await flushPromises();
    expect(wrapper.findComponent(FormulateGrouping).vm.items).toEqual([{}])
  })

  it('allows repeatable groups to initialize with an empty array', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          type="group"
          name="test"
          :repeatable="true"
          v-model="model"
        >
          <div class="repeatable" />
        </FormulateInput>
      `,
      data () {
        return {
          model: []
        }
      }
    })
    await flushPromises();
    expect(wrapper.findComponent(FormulateGrouping).vm.items).toEqual([])
  })

  it('sets data-has-value on parent when any child has a value', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          type="group"
          name="test"
          :repeatable="true"
          v-model="model"
        >
          <FormulateInput
            name="field"
            type="text"
          />
        </FormulateInput>
      `,
      data () {
        return {
          model: [{}, {}]
        }
      }
    })
    await flushPromises();
    expect(wrapper.attributes('data-has-value')).toBe(undefined)
    wrapper.find('input').setValue('a value')
    await flushPromises()
    expect(wrapper.attributes('data-has-value')).toBe('true')
  })

  it('allows group specific classes to be extended', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          type="group"
          name="test"
          :repeatable="true"
          v-model="model"
          :grouping-class="['g-1-test']"
          :group-repeatable-class="['g-2-test']"
          :group-repeatable-remove-class="['g-3-test']"
          :group-add-more-class="['g-4-test']"
        >
          <FormulateInput
            name="field"
            type="text"
          />
        </FormulateInput>
      `,
      data () {
        return {
          model: [{}]
        }
      }
    })
    await flushPromises();

    expect(wrapper.findComponent(FormulateGrouping).attributes('class'))
      .toBe('formulate-input-grouping g-1-test')

    expect(wrapper.find('.formulate-input-group-repeatable').attributes('class'))
      .toBe('formulate-input-group-repeatable g-2-test')

    expect(wrapper.find('.formulate-input-group-repeatable-remove').attributes('class'))
      .toBe('formulate-input-group-repeatable-remove g-3-test')

    expect(wrapper.find('.formulate-input-group-add-more').attributes('class'))
      .toBe('formulate-input-group-add-more g-4-test')
  })

  it('has the proper formValues when using a custom validation message', async () => {
    const custom = jest.fn()
    const wrapper = mount({
      template: `
        <FormulateForm>
          <FormulateInput
            type="group"
            name="test"
            v-model="model"
          >
            <FormulateInput
              name="username"
              type="text"
            />
            <FormulateInput
              name="email"
              type="text"
              validation="email"
              :validation-messages="{
                email: custom
              }"
            />
          </FormulateInput>
        </FormulateForm>
      `,
      data () {
        return {
          model: [{username: 'person', email: 'person@example'}]
        }
      },
      methods: {
        custom
      }
    })
    await flushPromises();
    expect(custom.mock.calls[0][0].formValues).toEqual({
      test: [{username: 'person', email: 'person@example'}]
    })
  })

  // This is basically the same test as found in FormulateForm since they share registry logic.
  it('can swap input types with the same name without loosing registration, but resetting values', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formData"
        >
          <FormulateInput type="group" name="languages">
            <div key="it" v-if="lang === 'it'" data-is-italian>
              <FormulateInput type="text" name="test" label="Il tuo nome" />
            </div>
            <div key="en" v-else data-is-english>
              <FormulateInput type="text" name="test" label="Your name please" />
            </div>
          </FormulateInput>
          <FormulateInput type="text" name="country" value="it" />
        </FormulateForm>
      `,
      data () {
        return {
          lang: 'it',
          formData: {}
        }
      }
    })
    await flushPromises()
    wrapper.find('input[name="test"]').setValue('Justin')
    await flushPromises()
    expect(wrapper.vm.formData).toEqual({ country: 'it', languages: [{ test: 'Justin' }] })
    wrapper.setData({ lang: 'en' })
    await flushPromises()
    expect(wrapper.findComponent(FormulateRepeatableProvider).vm.registry.has('test')).toBe(true)
    expect(wrapper.findComponent(FormulateRepeatableProvider).vm.proxy).toEqual({})
    expect(wrapper.findComponent(FormulateForm).vm.proxy).toEqual({ country: 'it', languages: [{}] })
  })

  it('places remove slot before inputs by default', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'group', repeatable: true },
      slots: {
        default: '<FormulateInput type="text" />'
      }
    })
    expect(wrapper.findAll('.formulate-input-group-repeatable-remove + .formulate-input').length).toBe(1)
  })

  it('allows remove slot position to be overwritten by removePosition prop', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'group', repeatable: true, removePosition: 'after' },
      slots: {
        default: '<FormulateInput type="text" />'
      }
    })
    expect(wrapper.findAll('.formulate-input + .formulate-input-group-repeatable-remove').length).toBe(1)
  })

  it('scopes to the confirm rule to only the current group inputs.', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: {
        name: 'passwords',
        type: 'group'
      },
      slots: {
        default: `
          <div>
            <FormulateInput type="password" name="password" error-behavior="live" validation="required" value="abc" />
            <FormulateInput type="password" name="password_confirm" error-behavior="live" validation="confirm" value="abc" />
          </div>`
      }
    })
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors').exists()).toBeFalsy()
  })

  it('allows passing errors down into groups', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: {
        name: 'users',
        type: 'group',
        value: [{ username: 'mermaid', email: 'mermaid@wearebraid.com' }],
        groupErrors: {
          '0.username': ['This username is taken cause errbody wanna be a mermaid.']
        }
      },
      slots: {
        default: `
          <div>
            <FormulateInput name="username" error-behavior="live" />
            <FormulateInput name="email" error-behavior="live" />
          </div>`
      }
    })
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors').exists()).toBeTruthy()
  })

  it('allows passing errors down into nested groups', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: {
        name: 'users',
        type: 'group',
        value: [{
          username: 'mermaid',
          email: 'mermaid@wearebraid.com',
          invites: [
            { email: 'andy@wearebraid.com' },
            { email: 'bill@wearebraid.com' }
          ]
        }],
        groupErrors: {
          '0.username': ['This username is taken cause errbody wanna be a mermaid.'],
          '0.invites.1.email': 'Bill is not a real person'
        }
      },
      slots: {
        default: `
          <div>
            <FormulateInput name="username" error-behavior="live" />
            <FormulateInput name="email" error-behavior="live" />
            <FormulateInput type="group" name="invites" :repeatable="true">
              <FormulateInput type="email" name="email" />
            </FormulateInput>
          </div>`
      }
    })
    await flushPromises()
    const inputs = wrapper.findAll('.formulate-input')
    // 0 - Outer wrapper
    // 1 - Username input
    // 2 - Email input
    // 3 - Invites group
    // 4 - Invites group -> 0 -> email
    // 5 - Invites group -> 1 -> email
    expect(inputs.at(5).find('.formulate-input-errors li').text()).toBe('Bill is not a real person')
  })

  it('allows passing errors down into groups', async () => {
    const removeListener = jest.fn()
    const wrapper = mount(FormulateInput, {
      propsData: {
        name: 'users',
        type: 'group',
        repeatable: true,
        value: [{ username: 'mermaid', email: 'mermaid@wearebraid.com' }, { username: 'blah', email: 'blah@wearebraid.com' }],
      },
      listeners: {
        'repeatableRemoved': removeListener
      },
      slots: {
        default: `
          <FormulateInput name="username" error-behavior="live" />
          <FormulateInput name="email" error-behavior="live" />
        `
      }
    })
    await flushPromises()
    wrapper.find('.formulate-input-group-repeatable-remove').trigger('click')
    await flushPromises()
    expect(removeListener.mock.calls.length).toBe(1)
  })

  it('allows passing errors down into groups', async () => {
    const addListener = jest.fn()
    const wrapper = mount(FormulateInput, {
      propsData: {
        name: 'users',
        type: 'group',
        repeatable: true,
        value: [{}],
      },
      listeners: {
        'repeatableAdded': addListener
      },
      slots: {
        default: `
          <FormulateInput name="username" error-behavior="live" />
          <FormulateInput name="email" error-behavior="live" />
        `
      }
    })
    await flushPromises()
    wrapper.find('.formulate-input-group-add-more button').trigger('click')
    await flushPromises()
    expect(addListener.mock.calls.length).toBe(1)
  })

  it('ensures there are always a minimum number of items even if the model has fewer', async () => {
    const wrapper = mount({
      template: `<FormulateInput
        type="group"
        :minimum="5"
        v-model="names"
      >
        <FormulateInput name="name" />
      </FormulateInput>`,
      data () {
        return {
          names: [{name: 'a' }, {name: 'b'}, {name: 'c'}]
        }
      }
    })
    await flushPromises()
    const inputs = wrapper.findAll('input[name="name"]')
    expect(inputs.length).toBe(5)
    expect(wrapper.vm.names).toEqual([{name: 'a' }, {name: 'b'}, {name: 'c'}])
    inputs.at(4).setValue('bob')
    await flushPromises()
    expect(wrapper.vm.names).toEqual([{name: 'a' }, {name: 'b'}, {name: 'c'}, {}, {name: 'bob'}])
  })

  it('can add items on a group that is artificially filled to minimum length', async () => {
    const wrapper = mount({
      template: `<FormulateInput
        type="group"
        :minimum="5"
        :repeatable="true"
        v-model="names"
      >
        <FormulateInput name="name" />
      </FormulateInput>`,
      data () {
        return {
          names: [{name: 'a' }, {name: 'b'}, {name: 'c'}]
        }
      }
    })
    await flushPromises()
    expect(wrapper.findAll('input[name="name"]').length).toBe(5)
    wrapper.find('.formulate-input-group-add-more button').trigger('click')
    await flushPromises()
    expect(wrapper.findAll('input[name="name"]').length).toBe(6)
    expect(wrapper.vm.names.length).toBe(6)
  })

  it('allows slot injection of of a prefix and suffix', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          type="group"
          label="money"
        >
          <template #prefix="{ label }">
            <span>\${{ label }}</span>
          </template>
          <template #suffix="{ label }">
            <span>after {{ label }}</span>
          </template>
          <div></div>
        </FormulateInput>
      `
    })
    expect(wrapper.find('.formulate-input-element > span').text()).toBe('$money')
    expect(wrapper.find('.formulate-input-element > *:last-child').text()).toBe('after money')
  })

  it('is able to set/remove the proper values when using nested repeatable groups', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          v-model="users"
          name="users"
          type="group"
          :repeatable="true"
          >
          <template #remove="{ removeItem }">
            <a href="" class="remove-user" @click.prevent="removeItem">Remove</a>
          </template>
          <FormulateInput
            type="text"
            name="username"
          />
          <FormulateInput
            type="group"
            name="social"
            :repeatable="true"
          >
            <FormulateInput
              name="platform"
              type="select"
              :options="['Twitter', 'Facebook', 'Instagram']"
            />
            <FormulateInput
              name="handles"
              type="group"
              :options="['Twitter', 'Facebook', 'Instagram']"
            >
              <FormulateInput
                type="text"
                name="handle"
              />
            </FormulateInput>
          </FormulateInput>
        </FormulateInput>
      `,
      data () {
        return {
          users: [
            {
              username: 'Jon',
              social: [{ platform: 'Twitter', handles: [{ handle: '@jon' }] }, { platform: 'Facebook', handles: [{ handle: '@fb-jon' }] }]
            },
            {
              username: 'Jane',
              social: [{ platform: 'Instagram', handles: [{ handle: '@jane' }] }, { platform: 'Facebook', handles: [{ handle: '@fb-jane' }] }]
            }
          ]
        }
      }
    })
    await flushPromises()
    wrapper.findAll('[name="username"]').wrappers.map(wrapper => wrapper.element.value)
    // Make sure the top level fields have the right values
    expect(
      wrapper.findAll('[name="username"]').wrappers.map(wrapper => wrapper.element.value)
    ).toEqual(['Jon', 'Jane'])

    // Make sure the secondary depth fields have the right values
    expect(
      wrapper.findAll('select').wrappers.map(wrapper => wrapper.element.value)
    ).toEqual(['Twitter', 'Facebook', 'Instagram', 'Facebook'])

    // Remove the first user
    wrapper.find('.remove-user').trigger('click')
    await flushPromises()

    // Expect the first username to now be the second user
    expect(
      wrapper.findAll('[name="username"]').wrappers.map(wrapper => wrapper.element.value)
    ).toEqual(['Jane'])

    expect(
      wrapper.findAll('select').wrappers.map(wrapper => wrapper.element.value)
    ).toEqual(['Instagram', 'Facebook'])

    wrapper.find('.formulate-input-group-repeatable-remove').trigger('click')
    await flushPromises()

    expect(
      wrapper.findAll('select').wrappers.map(wrapper => wrapper.element.value)
    ).toEqual(['Facebook'])

    expect(
      wrapper.findAll('[name="handle"]').wrappers.map(wrapper => wrapper.element.value)
    ).toEqual(['@fb-jane'])
  })

  it('does not let checkboxes wipe their own value out', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formData"
        >
          <FormulateInput
            name="pizzas"
            type="group"
            :repeatable="true"
          >
            <FormulateInput
              type="checkbox"
              name="flavors"
              :options="options"
            />
          </FormulateInput>
        </FormulateForm>
      `,
      data () {
        return {
          options: ['cheese', 'pepperoni', 'pineapple', 'sausage'],
          formData: {
            pizzas: [{ flavors: ['pepperoni', 'pineapple'] }]
          }
        }
      }
    })
    await flushPromises()
    expect(wrapper.vm.formData).toEqual({
      pizzas: [{ flavors: ['pepperoni', 'pineapple'] }]
    })
  })
})
