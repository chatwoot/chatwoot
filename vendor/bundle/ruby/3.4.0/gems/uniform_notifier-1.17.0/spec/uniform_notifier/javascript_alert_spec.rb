# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UniformNotifier::JavascriptAlert do
  it 'should not notify message' do
    expect(UniformNotifier::JavascriptAlert.inline_notify(title: 'javascript alert!')).to be_nil
  end

  it 'should notify message' do
    UniformNotifier.alert = true
    expect(UniformNotifier::JavascriptAlert.inline_notify(title: 'javascript alert!')).to eq <<~CODE
      <script type="text/javascript">/*<![CDATA[*/
      alert( "javascript alert!" );
      /*]]>*/</script>
    CODE
  end

  it 'should accept custom attributes' do
    UniformNotifier.alert = { attributes: { :nonce => 'my-nonce', 'data-key' => :value } }
    expect(UniformNotifier::JavascriptAlert.inline_notify(title: 'javascript alert!')).to eq <<~CODE
      <script type="text/javascript" nonce="my-nonce" data-key="value">/*<![CDATA[*/
      alert( "javascript alert!" );
      /*]]>*/</script>
    CODE
  end

  it 'should have default attributes if no attributes settings exist' do
    UniformNotifier.alert = {}
    expect(UniformNotifier::JavascriptAlert.inline_notify(title: 'javascript alert!')).to eq <<~CODE
      <script type="text/javascript">/*<![CDATA[*/
      alert( "javascript alert!" );
      /*]]>*/</script>
    CODE
  end
end
