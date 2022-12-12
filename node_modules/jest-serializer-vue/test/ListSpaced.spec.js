import { shallow } from '@vue/test-utils'
import ListSpaced from './components/ListSpaced.vue'

describe('ListSpaced.vue', () => {
  it('hasn\'t changed snapshot', () => {
    const wrapper = shallow(ListSpaced)
    expect(wrapper.html()).toMatchSnapshot()
  })
})
