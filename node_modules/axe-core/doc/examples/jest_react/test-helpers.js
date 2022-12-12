import { configure, mount } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';

configure({ adapter: new Adapter() });

let wrapper;
export function mountToDoc(reactElm) {
  if (!document) {
    // Set up a basic DOM
    global.document = jsdom('<!doctype html><html><body></body></html>');
  }
  if (!wrapper) {
    wrapper = document.createElement('main');
    document.body.appendChild(wrapper);
  }

  const container = mount(reactElm);
  wrapper.innerHTML = '';
  wrapper.appendChild(container.getDOMNode());
  return container;
}
