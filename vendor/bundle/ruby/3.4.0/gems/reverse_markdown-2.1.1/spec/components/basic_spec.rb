require 'spec_helper'

describe ReverseMarkdown do

  let(:input)    { File.read('spec/assets/basic.html') }
  let(:document) { Nokogiri::HTML(input) }
  subject { ReverseMarkdown.convert(input) }

  it { is_expected.to match /plain text ?\n/ }
  it { is_expected.to match /# h1\n/ }
  it { is_expected.to match /## h2\n/ }
  it { is_expected.to match /### h3\n/ }
  it { is_expected.to match /#### h4\n/ }
  it { is_expected.to match /##### h5\n/ }
  it { is_expected.to match /###### h6\n/ }

  it { is_expected.to match /_em tag content_/ }
  it { is_expected.to match /before and after empty em tags/ }
  it { is_expected.to match /before and after em tags containing whitespace/ }
  it { is_expected.to match /_double em tags_/ }
  it { is_expected.to match /_double em tags in p tag_/ }
  it { is_expected.to match /a _em with leading and trailing_ whitespace/ }
  it { is_expected.to match /a _em with extra leading and trailing_ whitespace/ }

  it { is_expected.to match /\*\*strong tag content\*\*/ }
  it { is_expected.to match /before and after empty strong tags/ }
  it { is_expected.to match /before and after strong tags containing whitespace/ }
  it { is_expected.to match /\*\*double strong tags\*\*/ }
  it { is_expected.to match /\*\*double strong tags in p tag\*\*/ }
  it { is_expected.to match /before \*\*double strong tags containing whitespace\*\* after/ }
  it { is_expected.to match /a \*\*strong with leading and trailing\*\* whitespace/ }
  it { is_expected.to match /a \*\*strong with extra leading and trailing\*\* whitespace/ }

  it { is_expected.to match /_i tag content_/ }
  it { is_expected.to match /\*\*b tag content\*\*/ }

  it { is_expected.to match /br tags become double space followed by newline  \n/ }
  #it { should match /br tags XXX  \n/ }

  it { is_expected.to match /before hr \n\* \* \*\n after hr/ }

  it { is_expected.to match /section 1\n ?\nsection 2/ }
end
