require 'spec_helper'

describe ReverseMarkdown do

  let(:input)    { File.read('spec/assets/anchors.html') }
  let(:document) { Nokogiri::HTML(input) }
  subject { ReverseMarkdown.convert(input) }

  it { is_expected.to include '[Foobar](http://foobar.com)' }
  it { is_expected.to include '[Fubar](http://foobar.com "f\*\*\*\*\* up beyond all recognition")' }
  it { is_expected.to include '[**Strong foobar**](http://strong.foobar.com)' }

  it { is_expected.to include ' ![](http://foobar.com/logo.png) ' }
  it { is_expected.to include ' ![foobar image](http://foobar.com/foobar.png) ' }
  it { is_expected.to include ' ![foobar image 2](http://foobar.com/foobar2.png "this is the foobar image 2") ' }
  it { is_expected.to include 'no extra space before and after the anchor ([stripped](http://foobar.com)).'}
  it { is_expected.to include 'after an ! [there](http://not.an.image.foobar.com) should be an extra space.'}
  it { is_expected.to include 'with stripped elements inbetween: ! [there](http://still.not.an.image.foobar.com) should be an extra space.'}

  context "links to ignore" do
    it { is_expected.to include ' ignore anchor tags with no link text ' }
    it { is_expected.to include ' not ignore [![An Image](image.png)](foo.html) anchor tags with images' }
    it { is_expected.to include ' pass through the text of [internal jumplinks](#content) without treating them as links ' }
    it { is_expected.to include ' pass through the text of anchor tags with no href without treating them as links ' }
  end

end
