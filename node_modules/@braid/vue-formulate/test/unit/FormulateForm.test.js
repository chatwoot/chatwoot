import Vue from 'vue'
import { mount, shallowMount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import Formulate from '../../src/Formulate.js'
import FormSubmission from '../../src/FormSubmission.js'
import FormulateForm from '@/FormulateForm.vue'
import FormulateInput from '@/FormulateInput.vue'

Vue.use(Formulate, {
  classes: {
    form: ['bg-white py-10']
  },
  library: {
    onlyOut: {
      classification: 'text',
      component: {
        props: ['context'],
        render: function (h) {
          return h('div', {attrs: {'data-output': true }}, this.context.model)
        }
      }
    }
  }
})

describe('FormulateForm', () => {
  it('render a form DOM element', () => {
    const wrapper = mount(FormulateForm)
    expect(wrapper.find('form').exists()).toBe(true)
  })

  it('accepts a default slot', () => {
    const wrapper = mount(FormulateForm, {
      slots: {
        default: '<div class="default-slot-item" />'
      }
    })
    expect(wrapper.find('form div.default-slot-item').exists()).toBe(true)
  })

  it('intercepts submit event', () => {
    const formSubmitted = jest.fn()
    const wrapper = mount(FormulateForm, {
      slots: {
        default: "<button type='submit' />"
      }
    })
    const spy = jest.spyOn(wrapper.vm, 'formSubmitted')
    wrapper.find('form').trigger('submit')
    expect(spy).toHaveBeenCalled()
  })

  it('registers its subcomponents', () => {
    const wrapper = mount(FormulateForm, {
      propsData: { formulateValue: { testinput: 'has initial value' } },
      slots: { default: '<FormulateInput type="text" name="subinput1" /><FormulateInput type="checkbox" name="subinput2" />' }
    })
    expect(wrapper.vm.registry.keys()).toEqual(['subinput1', 'subinput2'])
  })

  it('deregisters a subcomponents', async () => {
    const wrapper = mount({
      data () {
        return {
          active: true
        }
      },
      template: `
        <FormulateForm>
          <FormulateInput v-if="active" type="text" name="subinput1" />
          <FormulateInput type="checkbox" name="subinput2" />
        </FormulateForm>
      `
    })
    await flushPromises()
    expect(wrapper.findComponent(FormulateForm).vm.registry.keys()).toEqual(['subinput1', 'subinput2'])
    wrapper.setData({ active: false })
    await flushPromises()
    expect(wrapper.findComponent(FormulateForm).vm.registry.keys()).toEqual(['subinput2'])
  })

  it('can set a field’s initial value', async () => {
    const wrapper = mount(FormulateForm, {
      propsData: { formulateValue: { testinput: 'has initial value' } },
      slots: { default: '<FormulateInput type="text" name="testinput" />' }
    })
    await flushPromises()
    expect(wrapper.find('input').element.value).toBe('has initial value')
  })

  it('lets individual fields override form initial value', () => {
    const wrapper = mount(FormulateForm, {
      propsData: { formulateValue: { testinput: 'has initial value' } },
      slots: { default: '<FormulateInput type="text" formulate-value="123" name="testinput" />' }
    })
    expect(wrapper.find('input').element.value).toBe('123')
  })

  it('lets fields set form initial value with value prop', () => {
    const wrapper = mount({
      data () {
        return {
          formValues: {}
        }
      },
      template: `<FormulateForm v-model="formValues">
        <FormulateInput name="name" value="123" />
      </FormulateForm>`
    })
    expect(wrapper.vm.formValues).toEqual({ name: '123' })
  })

  it('can set initial checked attribute on single checkboxes', () => {
    const wrapper = mount(FormulateForm, {
      propsData: { formulateValue: { box1: true } },
      slots: { default: '<FormulateInput type="checkbox" name="box1" />' }
    })
    expect(wrapper.find('input[type="checkbox"]').element.checked).toBeTruthy()
  });

  it('can set initial unchecked attribute on single checkboxes', () => {
    const wrapper = mount(FormulateForm, {
      propsData: { formulateValue: { box1: false } },
      slots: { default: '<FormulateInput type="checkbox" name="box1" />' }
    })
    expect(wrapper.find('input[type="checkbox"]').element.checked).toBeFalsy()
  });

  it('can set checkbox initial value with options', async () => {
    const wrapper = mount(FormulateForm, {
      propsData: { formulateValue: { box2: ['second', 'third'] } },
      slots: { default: '<FormulateInput type="checkbox" name="box2" :options="{first: \'First\', second: \'Second\', third: \'Third\'}" />' }
    })
    await flushPromises()
    expect(wrapper.findAll('input').length).toBe(3)
  });

  it('receives updates to form model when individual fields are edited', () => {
    const wrapper = mount({
      data () {
        return {
          formValues: {
            testinput: '',
          }
        }
      },
      template: `
        <FormulateForm v-model="formValues">
          <FormulateInput type="text" name="testinput" />
        </FormulateForm>
      `
    })
    wrapper.find('input').setValue('edited value')
    expect(wrapper.vm.formValues).toEqual({ testinput: 'edited value' })
  })



  // ===========================================================================
  /**
   * @todo in vue-test-utils version 1.0.0-beta.29 has some bugs related to
   * synchronous updating. Some details are here:
   *
   * @update this test was re-implemented in version 1.0.0-beta.31 and seems to
   * be workign now with flushPromises(). Leaving these docs here for now.
   *
   * https://github.com/vuejs/vue-test-utils/issues/1130
   *
   * This test is being commented out until there is a resolution on this issue,
   * and instead being replaced with a mock call.
   */

  it('updates initial form values when input contains a populated v-model', async () => {
    const wrapper = mount({
      data () {
        return {
          formValues: {
            testinput: '',
          },
          fieldValue: '123'
        }
      },
      template: `
        <FormulateForm v-model="formValues">
          <FormulateInput type="text" name="testinput" v-model="fieldValue" />
        </FormulateForm>
      `
    })
    await flushPromises()
    expect(wrapper.vm.formValues).toEqual({ testinput: '123' })
  })

  // ===========================================================================

  // Replacement test for the above test - not quite as good of a test.
  it('updates calls setFieldValue on form when a field contains a populated v-model on registration', () => {
    const wrapper = mount(FormulateForm, {
      propsData: {
        formulateValue: { testinput: '123' }
      },
      slots: {
        default: '<FormulateInput type="text" name="testinput" formulate-value="override-data" />'
      }
    })
    expect(wrapper.emitted().input[wrapper.emitted().input.length - 1]).toEqual([{ testinput: 'override-data' }])
  })

  it('updates an inputs value when the form v-model is modified', async () => {
    const wrapper = mount({
      data () {
        return {
          formValues: {
            testinput: 'abcd',
          }
        }
      },
      template: `
        <FormulateForm v-model="formValues">
          <FormulateInput type="text" name="testinput" />
        </FormulateForm>
      `
    })
    await flushPromises()
    wrapper.vm.formValues = { testinput: '1234' }
    await flushPromises()
    expect(wrapper.find('input[type="text"]').element.value).toBe('1234')
  })

  it('updates all inputs (even when not used in a field) when the v-model is modified', async () => {
    const wrapper = mount({
      data () {
        return {
          formValues: {
            testinputA: 'A',
            testinputB: 'B',
            extraProp: 'C'
          }
        }
      },
      template: `
        <div>
          <FormulateForm v-model="formValues">
            <FormulateInput ref="inputA" type="text" name="testinputA" />
          </FormulateForm>
          <FormulateForm v-model="formValues">
            <FormulateInput ref="inputB" type="text" name="testinputB" />
          </FormulateForm>
        </div>
      `
    })
    await flushPromises()
    wrapper.vm.formValues.testinputA = 'updatedA'
    wrapper.vm.formValues.testinputB = 'updatedB'
    await flushPromises()
    expect(wrapper.findAll('input[type="text"]').at(0).element.value).toBe('updatedA')
    expect(wrapper.findAll('input[type="text"]').at(1).element.value).toBe('updatedB')
    expect(wrapper.vm.formValues.testinputA).toBe('updatedA')
    expect(wrapper.vm.formValues.testinputB).toBe('updatedB')
    expect(wrapper.vm.formValues.extraProp).toBe('C')
  })

  it('emits an instance of FormSubmission', async () => {
    const submitRaw = jest.fn();
    const wrapper = mount(FormulateForm, {
      slots: { default: '<FormulateInput type="text" formulate-value="123" name="testinput" />' },
      listeners: { 'submit-raw': submitRaw }
    })
    wrapper.find('form').trigger('submit')
    await flushPromises()
    expect(submitRaw).toHaveBeenCalledWith(expect.any(FormSubmission))
  })

  it('resolves hasValidationErrors to true', async () => {
    const submitRaw = jest.fn()
    const wrapper = mount(FormulateForm, {
      slots: { default: '<FormulateInput type="text" validation="required" name="testinput" />' },
      listeners: { 'submit-raw': submitRaw }
    })
    wrapper.find('form').trigger('submit')
    await flushPromises()
    const submission = submitRaw.mock.calls[0][0]
    expect(await submission.hasValidationErrors()).toBe(true)
  })

  it('does not resolve a submitted form that doesnt have a handler', async () => {
    const wrapper = mount(FormulateForm, {
      slots: { default: '<FormulateInput type="text" validation="required" name="testinput" value="Justin" />' }
    })
    const submission = await wrapper.vm.formSubmitted()
    expect(submission).toEqual(false)
  })

  it('resolves a submitted form with a handler', async () => {
    const wrapper = mount(FormulateForm, {
      listeners: {
        submit: () => {}
      },
      slots: { default: '<FormulateInput type="text" validation="required" name="testinput" value="Justin" />' }
    })
    const submission = await wrapper.vm.formSubmitted()
    expect(submission).toEqual({ testinput: 'Justin' })
  })

  it('accepts a values prop and uses it to set the initial values', async () => {
    const wrapper = mount(FormulateForm, {
      propsData: { values: { name: 'Dave Barnett', candy: true } },
      slots: { default: `<FormulateInput type="text" name="name" validation="required" /><FormulateInput type="checkbox" name="candy" />` }
    })
    await flushPromises()
    expect(wrapper.find('input[type="text"]').element.value).toBe('Dave Barnett')
    expect(wrapper.find('input[type="checkbox"]').element.checked).toBe(true)
  })

  it('shows error messages when it includes a checkbox with options', async () => {
    const wrapper = mount(FormulateForm, {
      propsData: { formulateValue: { box3: [] } },
      slots: { default: '<FormulateInput type="checkbox" name="box3" validation="required" :options="{first: \'First\', second: \'Second\', third: \'Third\'}" />' }
    })
    wrapper.trigger('submit')
    await wrapper.vm.$nextTick()
    await flushPromises()
    expect(wrapper.find('.formulate-input-error').exists()).toBe(true)
  })

  it('renders the name attribute', async () => {
    const wrapper = mount(FormulateForm, {
      propsData: { name: 'login' }
    })
    expect(wrapper.attributes('name')).toBe('login')
  })

  it('automatically registers with root plugin', async () => {
    const wrapper = mount(FormulateForm, {
      propsData: { formulateValue: { box3: [] }, name: 'login' }
    })
    expect(wrapper.vm.$formulate.registry.has('login')).toBe(true)
    expect(wrapper.vm.$formulate.registry.get('login')).toBe(wrapper.vm)
  })

  it('calls custom error handler with error and name', async () => {
    const mockHandler = jest.fn((err, name) => err);
    const wrapper = mount({
      template: `
      <div>
        <FormulateForm
          name="login"
        />
        <FormulateForm
          name="register"
        />
      </div>
      `
    })
    wrapper.vm.$formulate.extend({ errorHandler: mockHandler })
    wrapper.vm.$formulate.handle({ formErrors: ['This is an error message'] }, 'login')
    expect(mockHandler.mock.calls.length).toBe(1);
    expect(mockHandler.mock.calls[0]).toEqual([{ formErrors: ['This is an error message'] }, 'login']);
  })

  it('errors are displayed on correctly named forms', async () => {
    const wrapper = mount({
      template: `
      <div>
        <FormulateForm
          name="login"
        />
        <FormulateForm
          name="register"
        />
      </div>
      `
    })
    expect(wrapper.vm.$formulate.registry.has('login') && wrapper.vm.$formulate.registry.has('register')).toBe(true)
    wrapper.vm.$formulate.handle({ formErrors: ['This is an error message'] }, 'login')
    await flushPromises()
    expect(wrapper.findAll('.formulate-form').length).toBe(2)
    expect(wrapper.find('.formulate-form--login .formulate-form-errors').exists()).toBe(true)
    expect(wrapper.find('.formulate-form--register .formulate-form-errors').exists()).toBe(false)
  })

  it('errors are displayed on correctly named forms', async () => {
    const wrapper = mount({
      template: `
      <div>
        <FormulateForm
          name="login"
        />
        <FormulateForm
          name="register"
        />
      </div>
      `
    })
    expect(wrapper.vm.$formulate.registry.has('login') && wrapper.vm.$formulate.registry.has('register')).toBe(true)
    wrapper.vm.$formulate.handle({ formErrors: ['This is an error message'] }, 'login')
    await flushPromises()
    expect(wrapper.findAll('.formulate-form').length).toBe(2)
    expect(wrapper.find('.formulate-form--login .formulate-form-errors').exists()).toBe(true)
    expect(wrapper.find('.formulate-form--register .formulate-form-errors').exists()).toBe(false)
  })

  it('de-registers named forms when destroyed', async () => {
    const wrapper = mount({
      template: `
      <div>
        <FormulateForm
          name="login"
          v-if="hasForm"
        />
        <FormulateForm
          name="register"
        />
      </div>
      `,
      data () {
        return {
          hasForm: true
        }
      }
    })
    await flushPromises()
    expect(wrapper.vm.$formulate.registry.has('login')).toBe(true)
    wrapper.vm.hasForm = false
    await flushPromises()
    expect(wrapper.vm.$formulate.registry.has('login')).toBe(false)
  })

  it('hides root FormError if another form error exists and renders in new location', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          name="login"
        >
          <h1>Login</h1>
          <FormulateErrors />
          <FormulateInput name="username" validation="required" error-behavior="live" />
        </FormulateForm>
      `
    })
    wrapper.vm.$formulate.handle({ formErrors: ['This is an error message'] }, 'login')
    await flushPromises()
    expect(wrapper.findAll('.formulate-form-errors').length).toBe(1)
    // Ensure that we moved the position of the errors
    expect(wrapper.find('h1 + *').element.classList.contains('formulate-form-errors')).toBe(true)
  })

  it('allows rendering multiple locations', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          name="login"
        >
          <h1>Login</h1>
          <FormulateErrors />
          <FormulateInput name="username" validation="required" error-behavior="live" />
          <FormulateErrors />
        </FormulateForm>
      `
    })
    wrapper.vm.$formulate.handle({ formErrors: ['This is an error message'] }, 'login')
    await flushPromises()
    expect(wrapper.findAll('.formulate-form-errors').length).toBe(2)
  })

  it('receives a form-errors prop and displays it', async () => {
    const wrapper = mount(FormulateForm, {
      propsData: { formErrors: ['first', 'second'] },
      slots: {
        default: '<FormulateInput name="name" />'
      }
    })
    await flushPromises()
    expect(wrapper.findAll('.formulate-form-error').length).toBe(2)
  })

  it('it aggregates form-errors prop with form-named errors', async () => {
    const wrapper = mount(FormulateForm, {
      propsData: { formErrors: ['first', 'second'], name: 'login' }
    })
    wrapper.vm.$formulate.handle({ formErrors: ['third'] }, 'login')
    await flushPromises()
    expect(wrapper.findAll('.formulate-form-error').length).toBe(3)
  })

  it('displays field errors on inputs with errors prop', async () => {
    const wrapper = mount(FormulateForm, {
      propsData: { errors: { sipple: ['This field has an error'] }},
      slots: {
        default: '<FormulateInput name="sipple" />'
      }
    })
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.formulate-input .formulate-input-error').exists()).toBe(true)
  })

  it('is able to display multiple errors on multiple elements', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          :errors="{inputA: ['first', 'second'], inputB: 'only one here', inputC: ['and one here']}"
        >
          <FormulateInput name="inputA" />
          <FormulateInput name="inputB" type="textarea" />
          <FormulateInput name="inputC" type="checkbox" />
        </FormulateForm>
        `
    })
    await wrapper.vm.$nextTick()
    expect(wrapper.findAll('.formulate-input-error').length).toBe(4)
  })

  it('it can set multiple field errors with handle()', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm name="register">
          <FormulateInput name="inputA" />
          <FormulateInput name="inputB" type="textarea" />
          <FormulateInput name="inputC" type="checkbox" />
        </FormulateForm>
        `
    })
    expect(wrapper.findAll('.formulate-input-error').length).toBe(0)
    wrapper.vm.$formulate.handle({ inputErrors: {inputA: ['first', 'second'], inputB: 'only one here', inputC: ['and one here']} }, "register")
    await wrapper.vm.$nextTick()
    await flushPromises()
    expect(wrapper.findAll('.formulate-input-error').length).toBe(4)
  })

  it('only sets 1 error when used on a FormulateGroup input', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          name="register"
          :errors="{order: 'this didnt work'}"
        >
          <FormulateInput name="order" type="checkbox" :options="{first: 'First', last: 'Last', middle: 'Middle'}" />
        </FormulateForm>
        `
    })
    await wrapper.vm.$nextTick()
    expect(wrapper.findAll('.formulate-input-error').length).toBe(1)
  })

  it('properly de-registers an observer when removed', async () => {
    const wrapper = mount({
      data () {
        return {
          hasField: true
        }
      },
      template: `
        <FormulateForm
          name="register"
          :errors="{order: 'this didnt work'}"
        >
          <FormulateInput v-if="hasField" name="order" type="checkbox" :options="{first: 'First', last: 'Last', middle: 'Middle'}" />
        </FormulateForm>
        `
    })
    await flushPromises()
    expect(wrapper.findComponent(FormulateForm).vm.errorObservers.length).toBe(1)
    wrapper.setData({ hasField: false })
    await flushPromises()
    expect(wrapper.findComponent(FormulateForm).vm.errorObservers.length).toBe(0)
  })

  it('emits correct validation event on entry', async () => {
    const wrapper = mount(FormulateForm, {
      slots: { default: `
        <div>
          <FormulateInput type="text" validation="required|in:bar" name="testinput" />
          <FormulateInput type="radio" validation="required" name="bar" />
        </div>
      ` }
    })
    wrapper.find('input[type="text"]').setValue('foo')
    await flushPromises()
    const errorObjects = wrapper.emitted('validation')
    // There should be 3 events, both inputs mounting, and the value being set removing required on testinput
    expect(errorObjects.length).toBe(3)
    // this should be the event from the setValue()
    const errorObject = errorObjects[2][0]
    expect(errorObject).toEqual({
      name: 'testinput',
      errors: [
        expect.any(String)
      ],
      hasErrors: true
    })
  })

  it('emits correct validation event when no errors', async () => {
    const wrapper = mount(FormulateForm, {
      slots: { default: `
        <div>
          <FormulateInput type="text" validation="required|in:bar" name="testinput" />
          <FormulateInput type="radio" validation="required" name="bar" />
        </div>
      ` }
    })
    wrapper.find('input[type="text"]').setValue('bar')
    await flushPromises()
    const errorObjects = wrapper.emitted('validation')
    expect(errorObjects.length).toBe(3)
    const errorObject = errorObjects[2][0]
    expect(errorObject).toEqual({
      name: 'testinput',
      errors: [],
      hasErrors: false
    })
  })

  it('sets role="alert" attribute for form errors', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          name="login"
        />
      `
    })
    wrapper.vm.$formulate.handle({ formErrors: ['This is an error message', 'one more'] }, 'login')
    await flushPromises()
    expect(wrapper.find('[role="alert"]').exists()).toBe(true)
    expect(wrapper.findAll('[role="alert"]').length).toBe(2)
  })

  it('sets aria-live="assertive" attribute for form errors', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          name="register"
        />
      `
    })
    wrapper.vm.$formulate.handle({ formErrors: ['This is an error message', 'one more', 'one more again'] }, 'register')
    await flushPromises()
    expect(wrapper.find('[aria-live="assertive"]').exists()).toBe(true)
    expect(wrapper.findAll('[aria-live="assertive"]').length).toBe(3)
  })

  it('removes field data when that field is de-registered', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formData"
        >
          <FormulateInput type="text" name="foo" value="abc123" />
          <FormulateInput type="checkbox" name="bar" v-if="formData.foo !== 'bar'" :value="1" />
        </FormulateForm>
      `,
      data () {
        return {
          formData: {}
        }
      }
    })
    await flushPromises()
    wrapper.find('input[type="text"]').setValue('bar')
    await flushPromises()
    expect(wrapper.findComponent(FormulateForm).vm.proxy).toEqual({ foo: 'bar' })
    expect(wrapper.vm.formData).toEqual({ foo: 'bar' })
  })

  it('it allows the removal of properties in proxy.', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formData"
          name="login"
          ref="form"
        >
          <FormulateInput type="text" name="username" validation="required" v-model="username" />
          <FormulateInput type="password" name="password" validation="required|min:4,length" />
        </FormulateForm>
      `,
      data () {
        return {
          formData: {},
          username: undefined
        }
      }
    })
    wrapper.find('input[type="text"]').setValue('foo')
    await flushPromises()
    expect(wrapper.vm.username).toEqual('foo')
    expect(wrapper.vm.formData).toEqual({ username: 'foo' })
    wrapper.vm.$refs.form.setValues({})
    await flushPromises()
    expect(wrapper.vm.formData).toEqual({ username: '' })
  })

  it('it allows resetting a form, hiding validation and clearing inputs.', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formData"
          name="login"
        >
          <FormulateInput type="text" name="username" validation="required" />
          <FormulateInput type="password" name="password" validation="required|min:4,length" />
        </FormulateForm>
      `,
      data () {
        return {
          formData: {}
        }
      }
    })
    const password = wrapper.find('input[type="password"]')
    password.setValue('foo')
    password.trigger('blur')
    wrapper.find('form').trigger('submit')
    wrapper.vm.$formulate.handle({
      inputErrors: { username: ['Failed'] }
    }, 'login')
    await flushPromises()
    // First make sure we showed the errors
    expect(wrapper.findAll('.formulate-input-error').length).toBe(3)
    wrapper.vm.$formulate.reset('login')
    await flushPromises()
    expect(wrapper.findAll('.formulate-input-error').length).toBe(0)
    expect(wrapper.vm.formData).toEqual({})
  })

  it('re-validates dependent fields used in validation context', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formData"
          name="login"
        >
          <FormulateInput type="password" name="password" error-behavior="live" />
          <FormulateInput type="password" name="password_confirm" validation="confirm" error-behavior="live" />
        </FormulateForm>
      `,
      data () {
        return {
          formData: {
            password: 'foobar',
            password_confirm: 'foobar'
          }
        }
      }
    })
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors').exists()).toBe(false)
    const passwords = wrapper.findAll('input[type="password"]')
    passwords.at(1).setValue('123')
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors').exists()).toBe(true)
    passwords.at(0).setValue('123')
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors').exists()).toBe(false)
  })

  it('gracefully removes dependent fields when removed', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formData"
          name="login"
        >
          <FormulateInput type="password" name="password" error-behavior="live" />
          <FormulateInput type="password" name="password_confirm" validation="confirm" error-behavior="live" v-if="hasConfirm"/>
        </FormulateForm>
      `,
      data () {
        return {
          hasConfirm: true,
          formData: {
            password: 'foobar',
            password_confirm: 'foobar'
          }
        }
      }
    })
    await flushPromises()
    var inputs = wrapper.findAllComponents(FormulateInput)
    expect(wrapper.findComponent(FormulateForm).vm.deps.get(inputs.at(0).vm)).toEqual(new Set(['password_confirm']))
    expect(wrapper.findComponent(FormulateForm).vm.deps.get(inputs.at(1).vm)).toEqual(new Set(['password']))
    wrapper.vm.hasConfirm = false
    await flushPromises();
    inputs = wrapper.findAllComponents(FormulateInput)
    expect(inputs.length).toBe(1)
    expect(wrapper.findComponent(FormulateForm).vm.deps.get(inputs.at(0).vm)).toEqual(new Set([]))
  })

  it('allows form submission via named form', async () => {
    const submit = jest.fn()
    const wrapper = mount({
      template: `
        <FormulateForm
          name="password"
          @submit="submit"
        >
          <FormulateInput type="password" name="password"/>
          <FormulateInput type="password" name="password_confirm"/>
        </FormulateForm>
      `,
      data () {
        return {
          hasConfirm: true,
          formData: {
            password: 'foobar',
            password_confirm: 'foobar'
          }
        }
      },
      methods: {
        submit
      }
    })
    await flushPromises()
    wrapper.vm.$formulate.submit('password')
    await flushPromises()
    expect(submit.mock.calls.length).toBe(1)
  })

  it('fires the input event after the model has been updated', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formData"
        >
          <FormulateInput name="test" type="select" :options="{1: 'AAA', 2: 'BBB' }" @input="changed" />
        </FormulateForm>
      `,
      data () {
        return {
          formData: {},
          sameAsValue: null
        }
      },
      methods: {
        changed (value) {
          this.sameAsValue = this.formData.test === value
        }
      }
    })
    wrapper.find('select').setValue('2')
    await flushPromises()
    expect(wrapper.vm.formData.test).toBe('2')
    expect(wrapper.vm.sameAsValue).toBe(true)
  })

  it('properly hydrates when an initial value is zero', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formData"
        >
          <FormulateInput type="range" name="test" />
        </FormulateForm>
      `,
      data () {
        return {
          formData: {
            test: 0,
          }
        }
      }
    })
    await flushPromises()
    expect(wrapper.findComponent(FormulateInput).vm.context.model).toBe(0)
  })

  // This is basically the same test as found in FormulateInputGroup since they share registry logic.
  it('can swap input types with the same name without loosing registration, but resetting values', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formData"
        >
          <div key="it" v-if="lang === 'it'" data-is-italian>
            <FormulateInput type="text" name="test" label="Il tuo nome" />
          </div>
          <div key="en" v-else data-is-english>
            <FormulateInput type="text" name="test" label="Your name please" />
          </div>
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
    wrapper.find('input').setValue('Justin')
    await flushPromises()
    expect(wrapper.vm.formData.test).toBe('Justin')
    wrapper.setData({ lang: 'en' })
    await flushPromises()
    expect(wrapper.findComponent(FormulateForm).vm.registry.has('test')).toBe(true)
    expect(wrapper.findComponent(FormulateForm).vm.proxy).toEqual({ country: 'it' })
  })

  it('can keep values when keepModelData is set to true on an input', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formData"
        >
          <div key="it" v-if="lang === 'it'" data-is-italian>
            <FormulateInput type="text" name="test" :keep-model-data="true" label="Il tuo nome" />
          </div>
          <div key="en" v-else data-is-english>
            <FormulateInput type="text" name="test" :keep-model-data="true" label="Your name please" />
          </div>
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
    wrapper.find('input').setValue('JigglyPuff')
    await flushPromises()
    expect(wrapper.vm.formData.test).toBe('JigglyPuff')
    wrapper.setData({ lang: 'en' })
    await flushPromises()
    expect(wrapper.findComponent(FormulateForm).vm.registry.has('test')).toBe(true)
    expect(wrapper.findComponent(FormulateForm).vm.proxy).toEqual({ country: 'it', test: 'JigglyPuff' })
  })

  it('can keep values when keepModelData is set to true on a form', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formData"
          :keep-model-data="true"
        >
          <div key="it" v-if="lang === 'it'" data-is-italian>
            <FormulateInput type="text" name="test" label="Il tuo nome" />
          </div>
          <div key="en" v-else data-is-english>
            <FormulateInput type="text" name="test" label="Your name please" />
          </div>
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
    wrapper.find('input').setValue('JigglyPuff')
    await flushPromises()
    expect(wrapper.vm.formData.test).toBe('JigglyPuff')
    wrapper.setData({ lang: 'en' })
    await flushPromises()
    expect(wrapper.findComponent(FormulateForm).vm.registry.has('test')).toBe(true)
    expect(wrapper.findComponent(FormulateForm).vm.proxy).toEqual({ country: 'it', test: 'JigglyPuff' })
  })

  it('waits for one submission to finish before allowing the next one and exposes an isLoading prop', async () => {
    let resolveMe;
    const waitForMe = new Promise((resolve, reject) => resolveMe = resolve)

    const submit = jest.fn(() => waitForMe)
    const wrapper = mount({
      template: `
        <FormulateForm @submit="submit">
          <template #default="{ isLoading }">{{ isLoading ? "yes" : "no" }}</template>
        </FormulateForm>
      `,
      methods: {
        submit
      }
    })

    expect(wrapper.text()).toEqual('no')

    await wrapper.trigger('submit')
    await flushPromises()
    expect(submit).toHaveBeenCalledTimes(1)
    expect(wrapper.text()).toEqual('yes')

    // submit is still waiting for the previous call to finish
    await wrapper.trigger('submit')
    await flushPromises()
    expect(submit).toHaveBeenCalledTimes(1)
    expect(wrapper.text()).toEqual('yes')

    resolveMe()
    await flushPromises()
    expect(wrapper.text()).toEqual('no')

    // now it is resolved and the next submit can be called
    await wrapper.trigger('submit')
    await flushPromises()
    expect(submit).toHaveBeenCalledTimes(2)
    // This will resolve immediately since it has already been resolved
    expect(wrapper.text()).toEqual('no')
  })

  it('waits for a submit-raw to resolve before calling submit', async () => {
    let resolveMe;
    const waitForMe = new Promise((resolve, reject) => resolveMe = resolve)

    const submit = jest.fn(() => {})
    const submitRaw = jest.fn(() => waitForMe)
    const wrapper = mount({
      template: `
        <FormulateForm @submit="submit" @submitRaw="submitRaw">
          <template #default="{ isLoading }">{{ isLoading ? "yes" : "no" }}</template>
        </FormulateForm>
      `,
      methods: {
        submit,
        submitRaw
      }
    })

    expect(wrapper.text()).toEqual('no')

    await wrapper.trigger('submit')
    await flushPromises()
    expect(submitRaw).toHaveBeenCalledTimes(1)
    expect(submit).toHaveBeenCalledTimes(0)
    expect(wrapper.text()).toEqual('yes')
    resolveMe()
    await flushPromises()
    expect(submit).toHaveBeenCalledTimes(1)
  })

  it('ignored fields do not push their values to form', async () => {
    const wrapper = mount({
      template: `
      <FormulateForm>
        <FormulateInput name="search_users" ignored />
        <FormulateInput name="email" />
      </FormulateForm>
      `
    })
    await flushPromises()
    let registeredFields = wrapper.findComponent(FormulateForm).vm.registry.keys()
    expect(registeredFields.includes('search_users')).toBe(false)
    expect(registeredFields.includes('email')).toBe(true)
    wrapper.find('input').setValue('jon')
    await flushPromises()
    registeredFields = Object.keys(wrapper.findComponent(FormulateForm).vm.proxy)
    expect(registeredFields.includes('search_users')).toBe(false)
  })

  it('allows styling a form with a global form class', async () => {
    const wrapper = mount({
      template: `
      <FormulateForm name="search" class="abc" :form-class="['def']" data-has-this-attribute>
        <FormulateInput name="search_users" />
        <FormulateInput name="email" />
      </FormulateForm>
      `
    })
    await flushPromises()
    expect(Object.keys(wrapper.find('form').attributes())).toEqual(['data-has-this-attribute', 'name', 'class'])
    expect(wrapper.find('form').attributes('class')).toBe('abc formulate-form formulate-form--search bg-white py-10 def')
  })

  it('tracks it’s validation state with formContext', async () => {
    const wrapper = mount({
      template: `
      <FormulateForm #default="{ hasErrors }">
        <FormulateInput name="search_users" validation="required" />
        <FormulateInput name="email" validation="required|email" />
        <FormulateInput type="submit" :disabled="hasErrors" />
      </FormulateForm>
      `
    })
    await flushPromises()
    expect(wrapper.find('button[disabled]').exists()).toBe(true)
    const inputs = wrapper.findAll('input')
    const search = inputs.at(0)
    const email = inputs.at(1)
    search.setValue('justin')
    email.setValue('schroeder')
    await flushPromises()
    // Should still fail
    expect(wrapper.find('button[disabled]').exists()).toBe(true)
    email.setValue('hello@wearebraid.com')
    await flushPromises()
    // Should now pass
    expect(wrapper.find('button[disabled]').exists()).toBe(false)
  })

  it('emits a failed-validation error with references to all failing fields', async () => {
    const failed = jest.fn()
    const wrapper = mount({
      template: `
      <FormulateForm @failed-validation="failed">
        <FormulateInput name="search_users" validation="required" />
        <FormulateInput name="boxy" type="checkbox" :options="{a: 'A', b: 'B'}" validation="required" :value="['a']" />
        <FormulateInput name="email" validation="required|email" />
        <FormulateInput type="submit" />
      </FormulateForm>
      `,
      methods: {
        failed
      }
    })
    wrapper.find('form').trigger('submit')
    await flushPromises()
    const fields = wrapper.findAllComponents(FormulateInput)
    expect(Object.keys(failed.mock.calls[0][0])).toEqual(['search_users', 'email'])
    expect(failed.mock.calls[0][0].search_users).toBe(fields.at(0).vm)
  })

  it('Shows an error message when some of the fields are not validated on submit', async () => {
    const wrapper = mount({
      template: `
      <FormulateForm
        invalid-message="Not all the fields are valid."
      >
        <FormulateInput name="search_users" validation="required" />
        <FormulateInput name="boxy" type="checkbox" :options="{a: 'A', b: 'B'}" validation="required" :value="['a']" />
        <FormulateInput name="email" validation="required|email" />
        <FormulateInput type="submit" />
      </FormulateForm>
      `
    })
    wrapper.find('form').trigger('submit')
    await flushPromises()
    expect(wrapper.find('.formulate-form-errors li').text()).toBe('Not all the fields are valid.')
  })

  it('Shows an error message with invalid-message when using a function', async () => {
    const wrapper = mount({
      template: `
      <FormulateForm
        :invalid-message="(fields) => Object.keys(fields).join(', ')"
      >
        <FormulateInput name="search_users" validation="required" />
        <FormulateInput name="boxy" type="checkbox" :options="{a: 'A', b: 'B'}" validation="required" :value="['a']" />
        <FormulateInput name="email" type="email" validation="required|email" />
        <FormulateInput type="submit" />
      </FormulateForm>
      `
    })
    wrapper.find('form').trigger('submit')
    await flushPromises()
    expect(wrapper.find('.formulate-form-errors li').text()).toBe('search_users, email')
    wrapper.find('input').setValue('justin')
    wrapper.find('input[type="email"]').setValue('justin@wearebraid.com')
    await flushPromises()
    expect(wrapper.find('.formulate-form-errors').exists()).toBe(false)
  })

  it('can change form error wrapper and internal classes via class key props', async () => {
    const wrapper = mount({
      template: `
      <FormulateForm
        :form-errors="['some invalid thing happened']"
        :form-errors-class="['foobar']"
        form-error-class="error-message"
      >
        <span>Empty form</span>
      </FormulateForm>
      `
    })
    expect(wrapper.find('ul').attributes('class')).toBe('formulate-form-errors foobar')
    expect(wrapper.find('li').attributes('class')).toBe('error-message')
  })

  it('can change form error wrapper and internal classes via class key props with overridden FormErrors', async () => {
    const wrapper = mount({
      template: `
      <FormulateForm
        :form-errors="['some invalid thing happened']"
        :form-errors-class="['foobar']"
        form-error-class="error-message"
      >
        <span>Empty form</span>
        <FormulateErrors />
      </FormulateForm>
      `
    })
    expect(wrapper.find('span + ul').attributes('class')).toBe('formulate-form-errors foobar')
    expect(wrapper.find('span + ul > li').attributes('class')).toBe('error-message')
  })

  it('It allows state keys to be used on forms', async () => {
    const wrapper = mount({
      template: `
      <FormulateForm
        form-has-value-class="form-has-a-value"
      >
        <FormulateInput name="name" />
      </FormulateForm>
      `
    })
    expect(wrapper.find('form').attributes('class')).toBe('formulate-form bg-white py-10')
    wrapper.find('input').setValue('lauren')
    await flushPromises()
    expect(wrapper.find('form').attributes('class')).toBe('formulate-form bg-white py-10 form-has-a-value')
  })

  it('Allows mutating a number as value of v-modeled FormulateForm', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formValues"
        >
          <FormulateInput
            type="onlyOut"
            name="number"
          />
        </FormulateForm>
      `,
      data () {
        return {
          formValues: {
            number: 1234
          }
        }
      }
    })
    await flushPromises()
    expect(wrapper.find('[data-output]').text()).toBe('1234')
    wrapper.vm.formValues.number = 4567
    await flushPromises()
    expect(wrapper.find('[data-output]').text()).toBe('4567')
  })

  it('Can keep-model-data on box type inputs', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          v-model="formValues"
        >
          <FormulateInput
            v-if="showCheckboxes"
            type="checkbox"
            name="flavor"
            :keep-model-data="true"
            :options="options"
          />
        </FormulateForm>
      `,
      data () {
        return {
          showCheckboxes: true,
          options: ['Apple', 'Banana'],
          formValues: {}
        }
      }
    })
    wrapper.find('input[type="checkbox"]').setChecked(true)
    await flushPromises()
    expect(wrapper.vm.formValues).toEqual({ flavor: ['Apple'] })
    wrapper.vm.options = ['Pizza']
    await flushPromises()
    expect(wrapper.vm.formValues).toEqual({ flavor: ['Apple'] })
    wrapper.vm.showCheckboxes = false
    await flushPromises()
    expect(wrapper.vm.formValues).toEqual({ flavor: ['Apple'] })

  })
})
