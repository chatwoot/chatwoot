# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UniformNotifier::JavascriptConsole do
  it 'should not notify message' do
    expect(UniformNotifier::JavascriptConsole.inline_notify(title: 'javascript console!')).to be_nil
  end

  it 'should notify message' do
    UniformNotifier.console = true
    expect(UniformNotifier::JavascriptConsole.inline_notify(title: 'javascript console!')).to eq <<~CODE
      <script type="text/javascript">/*<![CDATA[*/
      if (typeof(console) !== 'undefined' && console.log) {
        if (console.groupCollapsed && console.groupEnd) {
          console.groupCollapsed(#{'Uniform Notifier'.inspect});
          console.log(#{'javascript console!'.inspect});
          console.groupEnd();
        } else {
          console.log(#{'javascript console!'.inspect});
        }
      }

      /*]]>*/</script>
    CODE
  end

  it 'should accept custom attributes' do
    UniformNotifier.console = { attributes: { :nonce => 'my-nonce', 'data-key' => :value } }
    expect(UniformNotifier::JavascriptConsole.inline_notify(title: 'javascript console!')).to eq <<~CODE
      <script type="text/javascript" nonce="my-nonce" data-key="value">/*<![CDATA[*/
      if (typeof(console) !== 'undefined' && console.log) {
        if (console.groupCollapsed && console.groupEnd) {
          console.groupCollapsed(#{'Uniform Notifier'.inspect});
          console.log(#{'javascript console!'.inspect});
          console.groupEnd();
        } else {
          console.log(#{'javascript console!'.inspect});
        }
      }

      /*]]>*/</script>
    CODE
  end

  it 'should have default attributes if no attributes settings exist' do
    UniformNotifier.console = {}
    expect(UniformNotifier::JavascriptConsole.inline_notify(title: 'javascript console!')).to eq <<~CODE
      <script type="text/javascript">/*<![CDATA[*/
      if (typeof(console) !== 'undefined' && console.log) {
        if (console.groupCollapsed && console.groupEnd) {
          console.groupCollapsed(#{'Uniform Notifier'.inspect});
          console.log(#{'javascript console!'.inspect});
          console.groupEnd();
        } else {
          console.log(#{'javascript console!'.inspect});
        }
      }

      /*]]>*/</script>
    CODE
  end
end
