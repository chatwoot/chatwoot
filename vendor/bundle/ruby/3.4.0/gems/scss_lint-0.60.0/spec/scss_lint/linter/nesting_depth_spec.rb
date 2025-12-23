require 'spec_helper'

describe SCSSLint::Linter::NestingDepth do
  context 'and selectors are nested up to depth 3' do
    let(:scss) { <<-SCSS }
      .one {
        .two {
          .three {
            background: #f00;
          }
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'and selectors are nested greater than depth 3' do
    let(:scss) { <<-SCSS }
      .one {
        .two {
          .three {
            .four {
              background: #f00;
            }
            .four-other {
              background: #f00;
            }
          }
        }
      }
    SCSS

    it { should report_lint line: 4 }
    it { should report_lint line: 7 }
  end

  context 'when max_depth is set to 1' do
    let(:linter_config) { { 'max_depth' => 1 } }

    context 'when nesting has a depth of one' do
      let(:scss) { <<-SCSS }
        .one {
          font-style: italic;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when nesting has a depth of two' do
      let(:scss) { <<-SCSS }
        .one {
          .two {
            font-style: italic;
          }
        }
        .one {
          font-style: italic;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when nesting has a depth of three' do
      let(:scss) { <<-SCSS }
        .one {
          .two {
            .three {
              background: #f00;
            }
          }
          .two-other {
            font-style: italic;
          }
        }
      SCSS

      it { should report_lint line: 2 }
      it { should report_lint line: 7 }
      it { should_not report_lint line: 3 }
    end

    context 'when nesting properties' do
      let(:scss) { <<-SCSS }
        .one {
          font: {
            family: monospace;
            style: italic;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when sequence contains a @keyframe' do
      let(:scss) { <<-SCSS }
        @keyframe my-keyframe {
          0% {
            background: #000;
          }

          50% {
            background: #fff;
          }
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'nesting parent selectors' do
    let(:scss) { <<-SCSS }
      .one {
        .two {
          .three {
            &:hover,
            &-suffix {
              .five {
                background: #f00;
              }
            }
          }

          .another-three { }
        }
      }
    SCSS

    context 'when parent selectors are ignored' do
      let(:linter_config) { { 'ignore_parent_selectors' => true } }

      context 'and max depth is set to 2' do
        let(:linter_config) { super().merge('max_depth' => 2) }

        it { should report_lint line: 3 }
        it { should report_lint line: 12 }
        it { should_not report_lint line: 4 }
        it { should_not report_lint line: 6 }
      end

      context 'and max depth is set to 3' do
        let(:linter_config) { super().merge('max_depth' => 3) }

        it { should_not report_lint line: 4 }
        it { should_not report_lint line: 5 }
        it { should report_lint line: 6 }
      end

      context 'and max depth is set to 4' do
        let(:linter_config) { super().merge('max_depth' => 4) }

        it { should_not report_lint }
      end

      context 'and sequence contains a keyframe' do
        let(:linter_config) { super().merge('max_depth' => 1) }
        let(:scss) { <<-SCSS }
        @keyframe my_keyframe {
            0% {
                background: none;
            }
            50% {
                background: red;
            }
        }
        SCSS

        it { should_not report_lint }
      end
    end

    context 'when not ignoring parent selectors' do
      let(:linter_config) { { 'ignore_parent_selectors' => false } }

      context 'and max depth is set to 2' do
        let(:linter_config) { super().merge('max_depth' => 2) }

        it { should report_lint line: 3 }
        it { should report_lint line: 12 }
        it { should_not report_lint line: 4 }
        it { should_not report_lint line: 6 }
      end

      context 'and max depth is set to 3' do
        let(:linter_config) { super().merge('max_depth' => 3) }

        it { should report_lint line: 4 }
        it { should_not report_lint line: 12 }
      end

      context 'and max depth is set to 4' do
        let(:linter_config) { super().merge('max_depth' => 4) }

        it { should report_lint line: 6 }
      end
    end
  end
end
