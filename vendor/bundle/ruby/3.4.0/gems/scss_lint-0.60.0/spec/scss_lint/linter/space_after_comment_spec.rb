require 'spec_helper'

describe SCSSLint::Linter::SpaceAfterComment do
  context 'when no comments exist' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when one space is preferred' do
    let(:linter_config) { { 'style' => 'one_space' } }

    context 'when silent comment and no space' do
      let(:scss) { <<-SCSS }
        //no space
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when silent comment and one space' do
      let(:scss) { <<-SCSS }
        // one space
      SCSS

      it { should_not report_lint line: 1 }
    end

    context 'when silent comment and multiple spaces' do
      let(:scss) { <<-SCSS }
        //   multiple spaces
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when silent three-slash comment' do
      let(:scss) { <<-SCSS }
        /// triple slash
      SCSS

      it { should_not report_lint }
    end

    context 'when silent four-slash comment' do
      let(:scss) { <<-SCSS }
        //// File-level annotations
      SCSS

      it { should_not report_lint }
    end

    context 'when inline silent comment and no space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; //no space
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when inline silent comment and one space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; // one space
        }
      SCSS

      it { should_not report_lint line: 2 }
    end

    context 'when inline silent comment and multiple spaces' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; //   multiple spaces
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when multiple silent comments' do
      let(:scss) { <<-SCSS }
       //no space
       // space
       //no space
       //   multiple spaces
      SCSS

      it { should report_lint line: 1 }
      it { should_not report_lint line: 2 }
      it { should report_lint line: 3 }
      it { should report_lint line: 4 }
    end

    context 'when multiple silent comments and allow_empty_comments' do
      let(:linter_config) { { 'style' => 'one_space', 'allow_empty_comments' => true } }
      let(:scss) { <<-SCSS }
       //
       //no space
       // space
       //no space
       //   multiple spaces
      SCSS

      it { should_not report_lint line: 1 }
      it { should report_lint line: 2 }
      it { should_not report_lint line: 3 }
      it { should report_lint line: 4 }
      it { should report_lint line: 5 }
    end

    context 'when normal comment and no space' do
      let(:scss) { <<-SCSS }
       /*no space */
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when normal comment and one space' do
      let(:scss) { <<-SCSS }
       /* one space */
      SCSS

      it { should_not report_lint line: 1 }
    end

    context 'when normal comment and multiple spaces' do
      let(:scss) { <<-SCSS }
       /*   multiple spaces */
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when inline normal comment and no space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; /*no space */
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when inline normal comment and one space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; /* one space */
        }
      SCSS

      it { should_not report_lint line: 2 }
    end

    context 'when inline normal comment and multiple space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; /*   multiple spaces */
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when loud comment and no space' do
      let(:scss) { <<-SCSS }
       /*!no space */
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when loud comment and one space' do
      let(:scss) { <<-SCSS }
       /*! one space */
      SCSS

      it { should_not report_lint line: 1 }
    end

    context 'when loud comment and multiple spaces' do
      let(:scss) { <<-SCSS }
       /*!   multiple spaces */
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when an indented block has comments on multiple lines' do
      let(:scss) { <<-SCSS }
        p {
          // Comment one
          // Comment two
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when no spaces are allowed' do
    let(:linter_config) { { 'style' => 'no_space' } }

    context 'when silent comment and no space' do
      let(:scss) { <<-SCSS }
        //no space
      SCSS

      it { should_not report_lint line: 1 }
    end

    context 'when silent comment and one space' do
      let(:scss) { <<-SCSS }
        // one space
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when silent comment and multiple spaces' do
      let(:scss) { <<-SCSS }
        //   multiple spaces
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when inline silent comment and no space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; //no space
        }
      SCSS

      it { should_not report_lint line: 2 }
    end

    context 'when inline silent comment and one space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; // one space
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when inline silent comment and multiple spaces' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; //   multiple spaces
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when multiple silent comments' do
      let(:scss) { <<-SCSS }
       //no space
       // space
       //no space
       //   multiple spaces
      SCSS

      it { should_not report_lint line: 1 }
      it { should report_lint line: 2 }
      it { should_not report_lint line: 3 }
      it { should report_lint line: 4 }
    end

    context 'when normal comment and no space' do
      let(:scss) { <<-SCSS }
       /*no space */
      SCSS

      it { should_not report_lint line: 1 }
    end

    context 'when normal comment and one space' do
      let(:scss) { <<-SCSS }
       /* one space */
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when normal comment and multiple spaces' do
      let(:scss) { <<-SCSS }
       /*   multiple spaces */
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when inline normal comment and no space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; /*no space */
        }
      SCSS

      it { should_not report_lint line: 2 }
    end

    context 'when inline normal comment and one space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; /* one space */
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when inline normal comment and multiple space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; /*   multiple spaces */
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when loud comment and no space' do
      let(:scss) { <<-SCSS }
       /*!no space */
      SCSS

      it { should_not report_lint line: 1 }
    end

    context 'when loud comment and one space' do
      let(:scss) { <<-SCSS }
       /*! one space */
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when loud comment and multiple spaces' do
      let(:scss) { <<-SCSS }
       /*!   multiple spaces */
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when an indented block has comments on multiple lines' do
      let(:scss) { <<-SCSS }
        p {
          //Comment one
          //Comment two
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when at least one space is preferred' do
    let(:linter_config) { { 'style' => 'at_least_one_space' } }

    context 'when silent comment and no space' do
      let(:scss) { <<-SCSS }
        //no space
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when silent comment and one space' do
      let(:scss) { <<-SCSS }
        // one space
      SCSS

      it { should_not report_lint line: 1 }
    end

    context 'when silent comment and multiple spaces' do
      let(:scss) { <<-SCSS }
        //   multiple spaces
      SCSS

      it { should_not report_lint line: 1 }
    end

    context 'when inline silent comment and no space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; //no space
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when inline silent comment and one space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; // one space
        }
      SCSS

      it { should_not report_lint line: 2 }
    end

    context 'when inline silent comment and multiple spaces' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; //   multiple spaces
        }
      SCSS

      it { should_not report_lint line: 2 }
    end

    context 'when multiple silent comments' do
      let(:scss) { <<-SCSS }
       //no space
       // space
       //no space
       //   multiple spaces
      SCSS

      it { should report_lint line: 1 }
      it { should_not report_lint line: 2 }
      it { should report_lint line: 3 }
      it { should_not report_lint line: 4 }
    end

    context 'when normal comment and no space' do
      let(:scss) { <<-SCSS }
       /*no space */
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when normal comment and one space' do
      let(:scss) { <<-SCSS }
       /* one space */
      SCSS

      it { should_not report_lint line: 1 }
    end

    context 'when normal comment and multiple spaces' do
      let(:scss) { <<-SCSS }
       /*   multiple spaces */
      SCSS

      it { should_not report_lint line: 1 }
    end

    context 'when inline normal comment and no space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; /*no space */
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when inline normal comment and one space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; /* one space */
        }
      SCSS

      it { should_not report_lint line: 2 }
    end

    context 'when inline normal comment and multiple space' do
      let(:scss) { <<-SCSS }
        p {
          margin:0; /*   multiple spaces */
        }
      SCSS

      it { should_not report_lint line: 2 }
    end

    context 'when loud comment and no space' do
      let(:scss) { <<-SCSS }
       /*!no space */
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when loud comment and one space' do
      let(:scss) { <<-SCSS }
       /*! one space */
      SCSS

      it { should_not report_lint line: 1 }
    end

    context 'when loud comment and multiple spaces' do
      let(:scss) { <<-SCSS }
       /*!   multiple spaces */
      SCSS

      it { should_not report_lint line: 1 }
    end

    context 'when an indented block has comments on multiple lines' do
      let(:scss) { <<-SCSS }
        p {
          // Comment one
          //  Comment two
        }
      SCSS

      it { should_not report_lint }
    end
  end
end
