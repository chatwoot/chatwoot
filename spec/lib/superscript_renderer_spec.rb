require 'rails_helper'

describe SuperscriptRenderer do
  let(:renderer) { described_class.new }

  def render_markdown(markdown)
    doc = CommonMarker.render_doc(markdown, :DEFAULT)
    renderer.render(doc)
  end

  describe '#text' do
    it 'converts text wrapped in ^ to superscript' do
      markdown = 'This is an example of a superscript: ^superscript^.'
      expect(render_markdown(markdown)).to include('<sup>superscript</sup>')
    end

    it 'does not convert text not wrapped in ^' do
      markdown = 'This is an example without superscript.'
      expect(render_markdown(markdown)).not_to include('<sup>')
    end

    it 'converts multiple superscripts in the same text' do
      markdown = 'This is an example with ^multiple^ ^superscripts^.'
      rendered_html = render_markdown(markdown)
      expect(rendered_html.scan('<sup>').length).to eq(2)
      expect(rendered_html).to include('<sup>multiple</sup>')
      expect(rendered_html).to include('<sup>superscripts</sup>')
    end
  end

  describe 'broken ^ usage' do
    it 'does not convert text that only starts with ^' do
      markdown = 'This is an example with ^broken superscript.'
      expected_output = '<p>This is an example with ^broken superscript.</p>'
      expect(render_markdown(markdown)).to include(expected_output)
    end

    it 'does not convert text that only ends with ^' do
      markdown = 'This is an example with broken^ superscript.'
      expected_output = '<p>This is an example with broken^ superscript.</p>'
      expect(render_markdown(markdown)).to include(expected_output)
    end

    it 'does not convert text with uneven numbers of ^' do
      markdown = 'This is an example with ^broken^ superscript^.'
      expected_output = '<p>This is an example with <sup>broken</sup> superscript^.</p>'
      expect(render_markdown(markdown)).to include(expected_output)
    end
  end
end
