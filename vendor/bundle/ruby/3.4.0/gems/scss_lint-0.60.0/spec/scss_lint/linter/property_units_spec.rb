require 'spec_helper'

describe SCSSLint::Linter::PropertyUnits do
  context 'when global units are set and local are not set' do
    let(:linter_config) { { 'global' => ['rem'], 'properties' => {} } }

    context 'when unit is allowed' do
      let(:scss) { <<-SCSS }
        p {
          font-size: 1.54rem;
          margin: 1rem;
          padding: .1rem;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when unit is not allowed' do
      let(:scss) { <<-SCSS }
        p {
          font-size: 16.54px;
          margin: 1px;
          padding: .1px;
        }
      SCSS

      it { should report_lint line: 2 }
      it { should report_lint line: 3 }
      it { should report_lint line: 4 }
    end

    context 'when using a shorthand property' do
      context 'and the unit is allowed' do
        let(:scss) { <<-SCSS }
          p {
            font: italic 1rem Serif;
          }
        SCSS

        it { should_not report_lint }
      end

      context 'and the unit is not allowed' do
        let(:scss) { <<-SCSS }
          p {
            font: italic 16px Serif;
          }
        SCSS

        it { should report_lint line: 2 }
      end

      context 'and some of the units are allowed but others are not allowed' do
        let(:scss) { <<-SCSS }
          p {
            margin: 1rem 1rem 16px 1rem;
          }
        SCSS

        it { should report_lint line: 2 }
      end

      context 'and it contains a quoted string with unit-like characterstics' do
        let(:scss) { <<-SCSS }
          p {
            font: italic 1rem "A 1a";
          }
        SCSS

        it { should_not report_lint }

        context 'and it contains other unallowed units' do
          let(:scss) { <<-SCSS }
            p {
              font: italic 1px "A 1a";
            }
          SCSS

          it { should report_lint }
        end
      end
    end
  end

  context 'when global and local units are set' do
    let(:linter_config) { { 'global' => ['rem'], 'properties' => { 'font-size' => ['px'] } } }

    context 'when unit is allowed locally not globally' do
      let(:scss) { <<-SCSS }
        p {
          font-size: 16px;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when unit is allowed globally not locally' do
      let(:scss) { <<-SCSS }
        p {
          margin: 1rem;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when unit is not allowed globally nor locally' do
      let(:scss) { <<-SCSS }
        p {
          margin: 1vh;
        }
      SCSS

      it { should report_lint line: 2 }
    end
  end

  context 'when local units are set and global are not set' do
    let(:linter_config) { { 'global' => [], 'properties' => { 'margin' => ['rem'] } } }

    context 'when unit is allowed locally not globally' do
      let(:scss) { <<-SCSS }
        p {
          margin: 1rem;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when unit is not allowed locally nor globally' do
      let(:scss) { <<-SCSS }
        p {
          margin: 10px;
        }
      SCSS

      it { should report_lint line: 2 }
    end
  end

  context 'when multiple units are set on a property' do
    let(:linter_config) { { 'global' => [], 'properties' => { 'margin' => %w[rem em] } } }

    context 'when one of multiple units is used' do
      let(:scss) { <<-SCSS }
        p {
          margin: 1rem;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when another of multiple units is used' do
      let(:scss) { <<-SCSS }
        p {
          margin: 1em;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when a not allowed unit is used' do
      let(:scss) { <<-SCSS }
        p {
          margin: 10px;
        }
      SCSS

      it { should report_lint line: 2 }
    end
  end

  context 'when no local units are allowed' do
    let(:linter_config) { { 'global' => ['px'], 'properties' => { 'line-height' => [] } } }

    context 'when a disallowed unit is used' do
      let(:scss) { <<-SCSS }
        p {
          line-height: 10px;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when no unit is used' do
      let(:scss) { <<-SCSS }
        p {
          line-height: 1;
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when nested properties are used' do
    let(:linter_config) { { 'global' => ['rem'], 'properties' => { 'font-size' => ['em'] } } }

    context 'and an allowed unit is used' do
      let(:scss) { <<-SCSS }
        p {
          font: {
            size: 1em;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'and a disallowed unit is used' do
      let(:scss) { <<-SCSS }
        p {
          font: {
            size: 16px;
          }
        }
      SCSS

      it { should report_lint line: 3 }
    end
  end

  context 'when property contains a function call' do
    let(:scss) { <<-SCSS }
      p {
        color: my-special-color(5);
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property contains a unicode sequence' do
    let(:scss) { <<-SCSS }
      p {
        content: "\\25be";
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property contains a string in quotes that looks like a value' do
    let(:scss) { <<-SCSS }
      p {
        content: "This is 12px";
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property contains a string in quotes that looks like a value with weird units' do
    let(:scss) { <<-SCSS }
      p {
        content: "This is 12a";
      }
    SCSS

    it { should_not report_lint }
  end
end
