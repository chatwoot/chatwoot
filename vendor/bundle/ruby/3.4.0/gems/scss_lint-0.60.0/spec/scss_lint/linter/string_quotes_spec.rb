require 'spec_helper'

describe SCSSLint::Linter::StringQuotes do
  context 'when string is written with single quotes' do
    let(:scss) { <<-SCSS }
      p {
        content: 'hello';
      }
    SCSS

    it { should_not report_lint }

    context 'and contains escaped single quotes' do
      let(:scss) { <<-SCSS }
        p {
          content: 'hello \\'world\\'';
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'and contains single quotes escaped as hex' do
      let(:scss) { <<-SCSS }
        p {
          content: 'hello \\27world\\27';
        }
      SCSS

      it { should_not report_lint }
    end

    context 'and contains double quotes' do
      let(:scss) { <<-SCSS }
        p {
          content: 'hello "world"';
        }
      SCSS

      it { should_not report_lint }
    end

    context 'and contains interpolation' do
      let(:scss) { <<-SCSS }
        p {
          content: 'hello \#{$world}';
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when @import uses single quotes' do
    let(:scss) { "@import 'file';" }

    it { should_not report_lint }

    context 'and has no trailing semicolon' do
      let(:scss) { "@import 'file'\n" }

      it { should_not report_lint }
    end
  end

  context 'when string is written with double quotes' do
    let(:scss) { <<-SCSS }
      p {
        content: "hello";
      }
    SCSS

    it { should report_lint line: 2 }

    context 'and contains escaped double quotes' do
      let(:scss) { <<-SCSS }
        p {
          content: "hello \\"world\\"";
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'and contains double quotes escaped as hex' do
      let(:scss) { <<-SCSS }
        p {
          content: "hello \\22world\\22";
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'and contains single quotes' do
      let(:scss) { <<-SCSS }
        p {
          content: "hello 'world'";
        }
      SCSS

      it { should_not report_lint }
    end

    context 'and contains interpolation' do
      let(:scss) { <<-SCSS }
        p {
          content: "hello \#{$world}"
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when @import uses double quotes' do
    let(:scss) { '@import "file";' }

    it { should report_lint }

    context 'and has no trailing semicolon' do
      let(:scss) { '@import "file"' }

      it { should report_lint }
    end
  end

  context 'when property has a literal identifier' do
    let(:scss) { <<-SCSS }
      p {
        display: none;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property is a URL with single quotes' do
    let(:scss) { <<-SCSS }
      p {
        background: url('image.png');
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property is a URL with double quotes' do
    let(:scss) { <<-SCSS }
      p {
        background: url("image.png");
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when Sass script is written in a non-silent comment' do
    let(:scss) { <<-SCSS }
      /**
       * .thing-\#{$key} {
       *   color: \#{value}
       * }
       */
    SCSS

    it { should_not report_lint }
  end

  context 'when the configuration has been set to prefer double quotes' do
    let(:linter_config) { { 'style' => 'double_quotes' } }

    context 'and string is written with single quotes' do
      let(:scss) { <<-SCSS }
        p {
          content: 'hello';
        }
      SCSS

      it { should report_lint line: 2 }

      context 'and contains escaped single quotes' do
        let(:scss) { <<-SCSS }
          p {
            content: 'hello \\'world\\'';
          }
        SCSS

        it { should report_lint line: 2 }
      end

      context 'and contains single quotes escaped as hex' do
        let(:scss) { <<-SCSS }
          p {
            content: 'hello \\27world\\27';
          }
        SCSS

        it { should report_lint line: 2 }
      end

      context 'and contains double quotes' do
        let(:scss) { <<-SCSS }
          p {
            content: 'hello "world"';
          }
        SCSS

        it { should_not report_lint }
      end

      context 'and contains interpolation' do
        let(:scss) { <<-SCSS }
          p {
            content: 'hello \#{$world}';
          }
        SCSS

        it { should_not report_lint }
      end

      context 'and contains interpolation inside a substring with single quotes' do
        let(:scss) { <<-SCSS }
          p {
            content: "<svg width='\#{$something}'>";
          }
        SCSS

        it { should_not report_lint }
      end

      context 'and contains a single-quoted string inside interpolation' do
        let(:scss) { <<-SCSS }
          p {
            content: "<svg width='\#{func('hello')}'>";
          }
        SCSS

        it { should report_lint }
      end
    end

    context 'and string is written with double quotes' do
      let(:scss) { <<-SCSS }
        p {
          content: "hello";
        }
      SCSS

      it { should_not report_lint }

      context 'and contains escaped double quotes' do
        let(:scss) { <<-SCSS }
          p {
            content: "hello \\"world\\"";
          }
        SCSS

        it { should report_lint line: 2 }
      end

      context 'and contains double quotes escaped as hex' do
        let(:scss) { <<-SCSS }
          p {
            content: "hello \\22world\\22";
          }
        SCSS

        it { should_not report_lint }
      end

      context 'and contains single quotes' do
        let(:scss) { <<-SCSS }
          p {
            content: "hello 'world'";
          }
        SCSS

        it { should_not report_lint }
      end

      context 'and contains interpolation' do
        let(:scss) { <<-SCSS }
          p {
            content: "hello \#{$world}";
          }
        SCSS

        it { should_not report_lint }
      end
    end

    context 'when property has a literal identifier' do
      let(:scss) { <<-SCSS }
        p {
          display: none;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when property is a URL with single quotes' do
      let(:scss) { <<-SCSS }
        p {
          background: url('image.png');
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when property is a URL with double quotes' do
      let(:scss) { <<-SCSS }
        p {
          background: url("image.png");
        }
      SCSS

      it { should_not report_lint }
    end
  end
end
