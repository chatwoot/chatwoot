require 'spec_helper'

describe SCSSLint::Linter::ElsePlacement do
  context 'when @if contains no accompanying @else' do
    let(:scss) { <<-SCSS }
      @if $condition {
        $var: 1;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when @else is on different line' do
    let(:scss) { <<-SCSS }
      @if $condition {
        $var: 1;
      }
      @else {
        $var: 0;
      }
    SCSS

    it { should report_lint line: 4 }
  end

  context 'when @else is on the same line as previous curly' do
    let(:scss) { <<-SCSS }
      @if $condition {
        $var: 1;
      } @else {
        $var: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when `@else if` is on different line' do
    let(:scss) { <<-SCSS }
      @if $condition {
        $var: 1;
      }
      @else if $other_condition {
        $var: 2;
      }
      @else {
        $var: 0;
      }
    SCSS

    it { should report_lint line: 4 }
    it { should report_lint line: 7 }
  end

  context 'when `@else if` is on the same line as previous curly' do
    let(:scss) { <<-SCSS }
      @if $condition {
        $var: 1;
      } @else if $other_condition {
        $var: 2;
      } @else {
        $var: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when @else is on same line as @if' do
    let(:scss) { <<-SCSS }
      @if $condition { $var: 1; } @else { $var: 0; }
    SCSS

    it { should_not report_lint }
  end

  context 'when @else nested in an @if is on new line' do
    let(:scss) { <<-SCSS }
      @if $condition {
        @if $condition2 {
          $var: 2;
        }
        @else {
          $var: 0;
        }
      } @else {
        $var: 1;
      }
    SCSS

    it { should report_lint line: 5 }
  end

  context 'when @else nested in an @else is on new line' do
    let(:scss) { <<-SCSS }
      @if $condition {
        $var: 1;
      } @else {
        @if $condition2 {
          $var: 2;
        }
        @else {
          $var: 0;
        }
      }
    SCSS

    it { should report_lint line: 7 }
  end

  context 'when placement of @else on a new line is preferred' do
    let(:linter_config) { { 'style' => 'new_line' } }

    context 'when @else is on a new line' do
      let(:scss) { <<-SCSS }
        @if $condition {
          $var: 1;
        }
        @else {
          $var: 0;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when @else is on the same line as previous curly brace' do
      let(:scss) { <<-SCSS }
        @if $condition {
          $var: 1;
        } @else {
          $var: 0;
        }
      SCSS

      it { should report_lint line: 3 }
    end
  end
end
