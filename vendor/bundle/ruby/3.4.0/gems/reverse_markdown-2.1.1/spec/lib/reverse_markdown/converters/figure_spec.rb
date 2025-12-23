require 'spec_helper'

describe ReverseMarkdown::Converters::Figure do

  let(:converter) { ReverseMarkdown::Converters::Figure.new }

  it 'handles figure tags with figcaption correctly' do
    node = node_for("<figure><img src='image.jpg' alt='img_alt'><figcaption>Figure Caption</figcaption></figure>")
    expect(converter.convert(node)).to eq "\n![img_alt](image.jpg)\n_Figure Caption_\n"
  end

  it 'handles figure tags without figcaption correctly' do
    node = node_for("<figure><img src='image.jpg' alt='img_alt'></figure>")
    expect(converter.convert(node)).to eq "\n![img_alt](image.jpg)\n"
  end

end
