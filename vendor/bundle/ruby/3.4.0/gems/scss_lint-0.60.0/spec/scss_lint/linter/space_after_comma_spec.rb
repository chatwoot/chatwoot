require 'spec_helper'

describe SCSSLint::Linter::SpaceAfterComma do
  let(:linter_config) { { 'style' => style } }

  context 'when one space is preferred' do
    let(:style) { 'one_space' }

    context 'in a mixin declaration' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        @mixin mixin($arg1,$arg2,$kwarg1: 'default',$kwarg2: 'default') {
        }
        SCSS

        it { should report_lint count: 3 }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        @mixin mixin($arg1, $arg2, $kwarg1: 'default', $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        @mixin mixin($arg1 , $arg2 , $kwarg1: 'default' , $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        @mixin mixin($arg1,
                     $arg2,
                     $kwarg1: 'default',
                     $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'definining a variable argument' do
        context 'where spaces do not follow commas' do
          let(:scss) { <<-SCSS }
          @mixin mixin($arg,$args...) {
          }
          SCSS

          it { should report_lint count: 1 }
        end

        context 'where spaces follow commas' do
          let(:scss) { <<-SCSS }
          @mixin mixin($arg, $args...) {
          }
          SCSS

          it { should_not report_lint }
        end

        context 'where spaces surround commas' do
          let(:scss) { <<-SCSS }
          @mixin mixin($arg , $args...) {
          }
          SCSS

          it { should_not report_lint }
        end

        context 'where commas are followed by a newline' do
          let(:scss) { <<-SCSS }
          @mixin mixin($arg,
                       $args...) {
          }
          SCSS

          it { should_not report_lint }
        end
      end
    end

    context 'in a mixin inclusion' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        p {
          @include mixin(1,2,3,$args...,$kwarg1: 4,$kwarg2: 5,$kwargs...);
        }
        SCSS

        it { should report_lint count: 6 }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        p {
          @include mixin(1, 2, 3, $args..., $kwarg1: 4, $kwarg2: 5, $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        p {
          @include mixin(1 , 2 , 3 , $args... , $kwarg1: 4 , $kwarg2: 5 , $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        p {
          @include mixin(1,
                         2,
                         3,
                         $args...,
                         $kwarg1: 4,
                         $kwarg2: 5,
                         $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end
    end

    context 'in a function declaration' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        @function func($arg1,$arg2,$kwarg1: 'default',$kwarg2: 'default') {
        }
        SCSS

        it { should report_lint count: 3 }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        @function func($arg1, $arg2, $kwarg1: 'default', $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        @function func($arg1 , $arg2 , $kwarg1: 'default' , $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        @function func($arg1,
                       $arg2,
                       $kwarg1: 'default',
                       $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'definining a variable argument' do
        context 'where spaces do not follow commas' do
          let(:scss) { <<-SCSS }
          @function func($arg,$args...) {
          }
          SCSS

          it { should report_lint count: 1 }
        end

        context 'where spaces follow commas' do
          let(:scss) { <<-SCSS }
          @function func($arg, $args...) {
          }
          SCSS

          it { should_not report_lint }
        end

        context 'where spaces surround commas' do
          let(:scss) { <<-SCSS }
          @function func($arg , $args...) {
          }
          SCSS

          it { should_not report_lint }
        end

        context 'where commas are followed by a newline' do
          let(:scss) { <<-SCSS }
          @function func($arg,
                         $args...) {
          }
          SCSS

          it { should_not report_lint }
        end
      end
    end

    context 'in a function invocation' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        p {
          margin: func(1,2,3,$args...,$kwarg1: 4,$kwarg2: 5,$kwargs...);
        }
        SCSS

        it { should report_lint count: 6 }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        p {
          margin: func(1, 2, 3, $args..., $kwarg1: 4, $kwarg2: 5, $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        p {
          margin: func(1 , 2 , 3 , $args... , $kwarg1: 4 , $kwarg2: 5 , $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        p {
          margin: func(1,
                       2,
                       3,
                       $args...,
                       $kwarg1: 4,
                       $kwarg2: 5,
                       $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end
    end

    context 'in a comma-separated literal list' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        p {
          property: $a,$b,$c,$d;
        }
        SCSS

        it { should report_lint count: 3 }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        p {
          property: $a, $b, $c, $d;
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        p {
          property: $a , $b , $c , $d;
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        p {
          property: $a,
                    $b,
                    $c,
                    $d;
        }
        SCSS

        it { should_not report_lint }
      end

      context 'when commas are followed by a space and a newline' do
        let(:scss) { <<-SCSS }
        p {
          property: $a,\s
                    $b;
        }
        SCSS

        it { should_not report_lint }
      end
    end

    context 'when declaring list variables' do
      context 'and one argument does not have a trailing comma' do
        let(:scss) { <<-SCSS }
        $z-list: (
          (
            name1
          ),
          (
            name2,
          )
        );
        SCSS

        it { should_not report_lint }
      end
    end

    context 'when map literal spans multiple lines' do
      let(:scss) { <<-SCSS }
      @include mixin('arg1', (
          key1: 'arg2-key1-value',
          key2: 'arg2-key2-value'
        ),$arg3: 'arg3-value', $arg4: 'arg4-value'
      );
      SCSS

      it { should report_lint line: 4 }
    end

    context 'column number' do
      let(:scss) { <<-SCSS }
      p {
        property: $a,$b;
      }
      SCSS

      it 'is the correct column' do
        subject.lints.first.location.column.should == 15
      end
    end

    context 'linter message' do
      let(:scss) { <<-SCSS }
      p {
        property: $a,$b;
      }
      SCSS

      it 'specifies the style' do
        subject.lints.first.description.should == 'Commas in lists should be followed by one space'
      end
    end
  end

  context 'when more than one space is preferred' do
    let(:style) { 'at_least_one_space' }

    context 'in a mixin declaration' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        @mixin mixin($arg1,$arg2,$kwarg1: 'default',$kwarg2: 'default') {
        }
        SCSS

        it { should report_lint count: 3 }
      end

      context 'where one space follows commas' do
        let(:scss) { <<-SCSS }
        @mixin mixin($arg1, $arg2, $kwarg1: 'default', $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where more than one space follows commas' do
        let(:scss) { <<-SCSS }
        @mixin mixin($arg1,     $arg2,  $kwarg1: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        @mixin mixin($arg1 , $arg2 , $kwarg1: 'default' , $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        @mixin mixin($arg1,
                     $arg2,
                     $kwarg1: 'default',
                     $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'definining a variable argument' do
        context 'where spaces do not follow commas' do
          let(:scss) { <<-SCSS }
          @mixin mixin($arg,$args...) {
          }
          SCSS

          it { should report_lint count: 1 }
        end

        context 'where spaces follow commas' do
          let(:scss) { <<-SCSS }
          @mixin mixin($arg, $args...) {
          }
          SCSS

          it { should_not report_lint }
        end

        context 'where multiple spaces follow commas' do
          let(:scss) { <<-SCSS }
          @mixin mixin($arg,    $args...) {
          }
          SCSS

          it { should_not report_lint }
        end

        context 'where spaces surround commas' do
          let(:scss) { <<-SCSS }
          @mixin mixin($arg , $args...) {
          }
          SCSS

          it { should_not report_lint }
        end

        context 'where commas are followed by a newline' do
          let(:scss) { <<-SCSS }
          @mixin mixin($arg,
                       $args...) {
          }
          SCSS

          it { should_not report_lint }
        end
      end
    end

    context 'in a mixin inclusion' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        p {
          @include mixin(1,2,3,$args...,$kwarg1: 4,$kwarg2: 5,$kwargs...);
        }
        SCSS

        it { should report_lint count: 6 }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        p {
          @include mixin(1, 2, 3, $args..., $kwarg1: 4, $kwarg2: 5, $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where multiple spaces follow commas' do
        let(:scss) { <<-SCSS }
        p {
          @include mixin(1,  2,  3,  $args...,  $kwarg1: 4,  $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        p {
          @include mixin(1 , 2 , 3 , $args... , $kwarg1: 4 , $kwarg2: 5 , $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        p {
          @include mixin(1,
                         2,
                         3,
                         $args...,
                         $kwarg1: 4,
                         $kwarg2: 5,
                         $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end
    end

    context 'in a function declaration' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        @function func($arg1,$arg2,$kwarg1: 'default',$kwarg2: 'default') {
        }
        SCSS

        it { should report_lint count: 3 }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        @function func($arg1, $arg2, $kwarg1: 'default', $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where multiple spaces follow commas' do
        let(:scss) { <<-SCSS }
        @function func($arg1,   $kwarg1: 'default',    $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        @function func($arg1 , $arg2 , $kwarg1: 'default' , $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        @function func($arg1,
                       $arg2,
                       $kwarg1: 'default',
                       $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'definining a variable argument' do
        context 'where spaces do not follow commas' do
          let(:scss) { <<-SCSS }
          @function func($arg,$args...) {
          }
          SCSS

          it { should report_lint count: 1 }
        end

        context 'where spaces follow commas' do
          let(:scss) { <<-SCSS }
          @function func($arg, $args...) {
          }
          SCSS

          it { should_not report_lint }
        end

        context 'where multiple spaces follow commas' do
          let(:scss) { <<-SCSS }
          @function func($arg,      $args...) {
          }
          SCSS

          it { should_not report_lint }
        end

        context 'where spaces surround commas' do
          let(:scss) { <<-SCSS }
          @function func($arg , $args...) {
          }
          SCSS

          it { should_not report_lint }
        end

        context 'where commas are followed by a newline' do
          let(:scss) { <<-SCSS }
          @function func($arg,
                         $args...) {
          }
          SCSS

          it { should_not report_lint }
        end
      end
    end

    context 'in a function invocation' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        p {
          margin: func(1,2,3,$args...,$kwarg1: 4,$kwarg2: 5,$kwargs...);
        }
        SCSS

        it { should report_lint count: 6 }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        p {
          margin: func(1, 2, 3, $args..., $kwarg1: 4, $kwarg2: 5, $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where multiple spaces follow commas' do
        let(:scss) { <<-SCSS }
        p {
          margin: func(1,  $args...,    $kwarg1: 4,   $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        p {
          margin: func(1 , 2 , 3 , $args... , $kwarg1: 4 , $kwarg2: 5 , $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        p {
          margin: func(1,
                       2,
                       3,
                       $args...,
                       $kwarg1: 4,
                       $kwarg2: 5,
                       $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end
    end

    context 'in a comma-separated literal list' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        p {
          property: $a,$b,$c,$d;
        }
        SCSS

        it { should report_lint count: 3 }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        p {
          property: $a, $b, $c, $d;
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where multiple spaces follow commas' do
        let(:scss) { <<-SCSS }
        p {
          property: $a,   $b,   $c,      $d;
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        p {
          property: $a , $b , $c , $d;
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        p {
          property: $a,
                    $b,
                    $c,
                    $d;
        }
        SCSS

        it { should_not report_lint }
      end

      context 'when commas are followed by a space and a newline' do
        let(:scss) { <<-SCSS }
        p {
          property: $a,\s
                    $b;
        }
        SCSS

        it { should_not report_lint }
      end
    end

    context 'when declaring list variables' do
      context 'and one argument does not have a trailing comma' do
        let(:scss) { <<-SCSS }
        $z-list: (
          (
            name1
          ),
          (
            name2,
          )
        );
        SCSS

        it { should_not report_lint }
      end
    end

    context 'linter message' do
      let(:scss) { <<-SCSS }
      p {
        property: $a,$b;
      }
      SCSS

      it 'specifies the style' do
        subject.lints.first.description.should ==
          'Commas in lists should be followed by at least one space'
      end
    end
  end

  context 'when no space is preferred' do
    let(:style) { 'no_space' }

    context 'in a mixin declaration' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        @mixin mixin($arg1,$arg2,$kwarg1: 'default',$kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        @mixin mixin($arg1, $arg2, $kwarg1: 'default', $kwarg2: 'default') {
        }
        SCSS

        it { should report_lint count: 3 }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        @mixin mixin($arg1 , $arg2 , $kwarg1: 'default' , $kwarg2: 'default') {
        }
        SCSS

        it { should report_lint count: 3 }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        @mixin mixin($arg1,
                     $arg2,
                     $kwarg1: 'default',
                     $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'definining a variable argument' do
        context 'where spaces do not follow commas' do
          let(:scss) { <<-SCSS }
          @mixin mixin($arg,$args...) {
          }
          SCSS

          it { should_not report_lint }
        end

        context 'where spaces follow commas' do
          let(:scss) { <<-SCSS }
          @mixin mixin($arg, $args...) {
          }
          SCSS

          it { should report_lint count: 1 }
        end

        context 'where spaces surround commas' do
          let(:scss) { <<-SCSS }
          @mixin mixin($arg , $args...) {
          }
          SCSS

          it { should report_lint count: 1 }
        end

        context 'where commas are followed by a newline' do
          let(:scss) { <<-SCSS }
          @mixin mixin($arg,
                       $args...) {
          }
          SCSS

          it { should_not report_lint }
        end
      end
    end

    context 'in a mixin inclusion' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        p {
          @include mixin(1,2,3,$args...,$kwarg1: 4,$kwarg2: 5,$kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        p {
          @include mixin(1, 2, 3, $args..., $kwarg1: 4, $kwarg2: 5, $kwargs...);
        }
        SCSS

        it { should report_lint count: 6 }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        p {
          @include mixin(1 , 2 , 3 , $args... , $kwarg1: 4 , $kwarg2: 5 , $kwargs...);
        }
        SCSS

        it { should report_lint count: 6 }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        p {
          @include mixin(1,
                         2,
                         3,
                         $args...,
                         $kwarg1: 4,
                         $kwarg2: 5,
                         $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end
    end

    context 'in a function declaration' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        @function func($arg1,$arg2,$kwarg1: 'default',$kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        @function func($arg1, $arg2, $kwarg1: 'default', $kwarg2: 'default') {
        }
        SCSS

        it { should report_lint count: 3 }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        @function func($arg1 , $arg2 , $kwarg1: 'default' , $kwarg2: 'default') {
        }
        SCSS

        it { should report_lint count: 3 }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        @function func($arg1,
                       $arg2,
                       $kwarg1: 'default',
                       $kwarg2: 'default') {
        }
        SCSS

        it { should_not report_lint }
      end

      context 'definining a variable argument' do
        context 'where spaces do not follow commas' do
          let(:scss) { <<-SCSS }
          @function func($arg,$args...) {
          }
          SCSS

          it { should_not report_lint }
        end

        context 'where spaces follow commas' do
          let(:scss) { <<-SCSS }
          @function func($arg, $args...) {
          }
          SCSS

          it { should report_lint count: 1 }
        end

        context 'where spaces surround commas' do
          let(:scss) { <<-SCSS }
          @function func($arg , $args...) {
          }
          SCSS

          it { should report_lint count: 1 }
        end

        context 'where commas are followed by a newline' do
          let(:scss) { <<-SCSS }
          @function func($arg,
                         $args...) {
          }
          SCSS

          it { should_not report_lint }
        end
      end
    end

    context 'in a function invocation' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        p {
          margin: func(1,2,3,$args...,$kwarg1: 4,$kwarg2: 5,$kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        p {
          margin: func(1, 2, 3, $args..., $kwarg1: 4, $kwarg2: 5, $kwargs...);
        }
        SCSS

        it { should report_lint count: 6 }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        p {
          margin: func(1 , 2 , 3 , $args... , $kwarg1: 4 , $kwarg2: 5 , $kwargs...);
        }
        SCSS

        it { should report_lint count: 6 }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        p {
          margin: func(1,
                       2,
                       3,
                       $args...,
                       $kwarg1: 4,
                       $kwarg2: 5,
                       $kwargs...);
        }
        SCSS

        it { should_not report_lint }
      end
    end

    context 'in a comma-separated literal list' do
      context 'where spaces do not follow commas' do
        let(:scss) { <<-SCSS }
        p {
          property: $a,$b,$c,$d;
        }
        SCSS

        it { should_not report_lint }
      end

      context 'where spaces follow commas' do
        let(:scss) { <<-SCSS }
        p {
          property: $a, $b, $c, $d;
        }
        SCSS

        it { should report_lint count: 3 }
      end

      context 'where spaces surround commas' do
        let(:scss) { <<-SCSS }
        p {
          property: $a , $b , $c , $d;
        }
        SCSS

        it { should report_lint count: 3 }
      end

      context 'where commas are followed by a newline' do
        let(:scss) { <<-SCSS }
        p {
          property: $a,
                    $b,
                    $c,
                    $d;
        }
        SCSS

        it { should_not report_lint }
      end

      context 'when commas are followed by a space and a newline' do
        let(:scss) { <<-SCSS }
        p {
          property: $a,\s
                    $b;
        }
        SCSS

        it { should_not report_lint }
      end
    end

    context 'when declaring list variables' do
      context 'and one argument does not have a trailing comma' do
        let(:scss) { <<-SCSS }
        $z-list: (
          (
            name1
          ),
          (
            name2,
          )
        );
        SCSS

        it { should_not report_lint }
      end
    end

    context 'linter message' do
      let(:scss) { <<-SCSS }
      p {
        property: $a, $b;
      }
      SCSS

      it 'specifies the style' do
        subject.lints.first.description.should == 'Commas in lists should be followed by no space'
      end
    end
  end
end
