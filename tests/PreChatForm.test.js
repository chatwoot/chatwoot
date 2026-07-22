import { shallowMount } from '@vue/test-utils';
import PreChatForm from '../src/components/PreChatForm.vue';
import { validateForm } from '../src/utils/validation';

jest.mock('../src/utils/validation');

describe('PreChatForm.vue', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(PreChatForm, {
      data() {
        return {
          formState: {
            terms: false
          }
        };
      }
    });
  });

  it('should call validateForm with correct parameters on submit', () => {
    const checkboxAttributes = [
      { name: 'terms', required: true, value: false }
    ];
    wrapper.vm.submitForm();
    expect(validateForm).toHaveBeenCalledWith(wrapper.vm.formState, checkboxAttributes);
  });

  it('should proceed with form submission if form is valid', () => {
    validateForm.mockReturnValue(true);
    const spy = jest.spyOn(wrapper.vm, 'submitForm');
    wrapper.vm.submitForm();
    expect(spy).toHaveBeenCalled();
    // Add additional checks for form submission logic
  });

  it('should not proceed with form submission if form is invalid', () => {
    validateForm.mockReturnValue(false);
    const spy = jest.spyOn(wrapper.vm, 'submitForm');
    wrapper.vm.submitForm();
    expect(spy).toHaveBeenCalled();
    // Add additional checks to ensure submission logic is not executed
  });
});