import { mount, shallow } from '@vue/test-utils'
import Empty from './components/Empty.vue'

describe('Empty.vue', () => {
  it('properly serializes a shallowly-rendered wrapper', () => {
    const wrapper = shallow(Empty)
    expect(wrapper).toMatchSnapshot()
  })

  it('properly serializes a fully-mounted wrapper', () => {
    const wrapper = mount(Empty)
    expect(wrapper).toMatchSnapshot()
  })
})
