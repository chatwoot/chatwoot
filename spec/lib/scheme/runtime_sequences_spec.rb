require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme::Runtime do
  subject(:runtime) { described_class.new }

  # Copy overlap and slice semantics follow R7RS-small sections 6.7 through 6.9.
  # https://standards.scheme.org/r7rs-html5/index.html
  {
    '(string-length "aλ🙂")' => '3',
    '(string-ref "aλ🙂" 2)' => '#\\🙂',
    '(substring "aλ🙂z" 1 3)' => '"λ🙂"',
    '(string-copy "abc" 3)' => '""',
    '(make-string 3 #\\x)' => '"xxx"',
    '(string-append "a" "λ" "c")' => '"aλc"',
    '(string-append)' => '""',
    '(let ((s (string-copy "abcde"))) (string-copy! s 1 s 0 4) s)' => '"aabcd"',
    '(let ((s (string-copy "abcde"))) (string-copy! s 0 s 1 5) s)' => '"bcdee"',
    '(let ((s (string-copy "abcde"))) (string-fill! s #\\x 1 4) s)' => '"axxxe"',
    '(let ((s (string-copy "abc"))) (string-copy! s 3 "") (string-fill! s #\\x 2 2) s)' => '"abc"',
    '(let ((s (string-copy "λ🙂"))) (string-set! s 0 #\\a) s)' => '"a🙂"',
    '(string-map (lambda (x y) y) "abc" "xy")' => '"xy"',
    '(let ((n 0)) (string-for-each (lambda (x) (set! n (+ n 1))) "λ🙂") n)' => '2',
    '(char->integer (integer->char 955))' => '955',
    '(char<? #\\a #\\b #\\c)' => '#t',
    '(char>=? #\\b #\\b #\\a)' => '#t',
    '(char=? #\\a #\\b)' => '#f',
    '(string>=? "c" "b" "b")' => '#t',
    '(string=? "a" "b")' => '#f',
    '(vector-length (make-vector 0))' => '0',
    '(make-vector 3 7)' => '#(7 7 7)',
    '(vector-copy #(1 2 3) 3)' => '#()',
    '(vector-append #(1 2) #() #(3))' => '#(1 2 3)',
    '(vector-append)' => '#()',
    '(let ((v (vector 1 2 3 4 5))) (vector-copy! v 1 v 0 4) v)' => '#(1 1 2 3 4)',
    '(let ((v (vector 1 2 3 4 5))) (vector-copy! v 0 v 1 5) v)' => '#(2 3 4 5 5)',
    '(let ((v (vector 1 2 3 4 5))) (vector-fill! v (quote x) 2 4) v)' => '#(1 2 x x 5)',
    '(let ((v (vector-copy #(1 2)))) (vector-set! v 0 3) v)' => '#(3 2)',
    '(vector-map + #(1 2 3) #(10 20))' => '#(11 22)',
    '(let ((n 0)) (vector-for-each (lambda (x) (set! n (+ n x))) #(1 2 3)) n)' => '6',
    '(vector->string (string->vector "aλ🙂z" 1 3))' => '"λ🙂"',
    '(list->vector (quote (1 2 3)))' => '#(1 2 3)',
    '(make-bytevector 3 255)' => '#u8(255 255 255)',
    '(bytevector-length #u8(0 255))' => '2',
    '(bytevector-u8-ref #u8(0 255) 1)' => '255',
    '(let ((v (bytevector 1 2 3))) (bytevector-u8-set! v 1 255) v)' => '#u8(1 255 3)',
    '(bytevector-append #u8(1) #u8() #u8(2 3))' => '#u8(1 2 3)',
    '(bytevector-copy #u8(1 2 3) 1 3)' => '#u8(2 3)',
    '(let ((v (bytevector 1 2 3 4))) (bytevector-copy! v 1 v 0 3) v)' => '#u8(1 1 2 3)',
    '(let ((v (bytevector 1 2 3 4))) (bytevector-copy! v 0 v 1 4) v)' => '#u8(2 3 4 4)',
    '(utf8->string (string->utf8 "aλ🙂z" 1 3))' => '"λ🙂"',
    '(utf8->string #u8(65 206 187 66) 1 3)' => '"λ"',
    '(let ((x (list 1))) (let ((v (vector x))) (set-car! (vector-ref (vector-copy v) 0) 9) x))' => '(9)',
    '(let ((x (list 1 2))) (let ((y (list-copy x))) (set-car! y 9) (list x y)))' => '((1 2) (9 2))',
    '(list-copy (quote (1 2 . 3)))' => '(1 2 . 3)',
    '(list-copy 3)' => '3',
    '(let ((x (list 1 2 3))) (list-set! x 1 9) x)' => '(1 9 3)',
    '(make-list 3 7)' => '(7 7 7)',
    '(append)' => '()',
    '(memq (quote b) (quote (a b c)))' => '(b c)',
    '(memv 2.0 (quote (1 2 3)))' => '#f',
    '(member 2 (quote (1 2.0 3)) =)' => '(2.0 3)',
    '(assoc 2 (quote ((1 . a) (2.0 . b))) =)' => '(2.0 . b)',
    '(assq (quote missing) (quote ((a . 1))))' => '#f',
    '(assv 2 (quote ((1 . a) (2 . b))))' => '(2 . b)',
    '(caddr (quote (1 2 3 4)))' => '3'
  }.each do |source, expected|
    it "evaluates #{source}" do
      expect(Scheme.write(runtime.evaluate(source))).to eq(expected)
    end
  end

  [
    '(string-ref "abc" -1)', '(string-ref "abc" 3)', '(string-ref "abc" 1.0)',
    '(substring "abc" 2 1)', '(substring "abc" 0 4)', '(make-string -1)', '(make-string 2 "x")',
    '(string-set! "abc" 0 #\\x)', '(string-copy! (string-copy "abc") 2 "xx")',
    '(string-map (lambda (c) 1) "x")', '(list->string (list "a"))',
    '(integer->char -1)', '(integer->char 55296)', '(integer->char 1114112)',
    '(vector-ref #(1 2) 2)', '(vector-ref #(1 2) -1)', '(vector-ref #(1 2) 0.0)',
    '(vector-copy #(1 2) 2 1)', '(vector-set! #(1 2) 0 3)', '(make-vector -1)',
    '(vector-copy! (vector 1) 1 #(2))', '(vector->string #(1))',
    '(bytevector 256)', '(bytevector -1)', '(bytevector 1.0)', '(make-bytevector 2 256)',
    '(bytevector-u8-set! (bytevector 1) 0 256)', '(bytevector-u8-set! #u8(1) 0 2)',
    '(bytevector-u8-ref #u8(1) 1)', '(bytevector-copy! (bytevector 1) 0 #u8(2 3))',
    '(utf8->string #u8(255))', '(utf8->string #u8(206))',
    '(vector-length #u8(1))', '(vector-set! (bytevector 1) 0 "invalid byte")',
    '(vector-fill! (bytevector 1) "invalid byte")', '(vector-copy #u8(1))',
    '(vector-append #u8(1))', '(vector->list #u8(1))', '(vector-map (lambda (x) x) #u8(1))',
    '(length (quote (1 . 2)))', '(list-ref (list 1) 1)', '(list-tail (list 1) -1)',
    '(list-set! (quote (1)) 0 2)', '(assq (quote x) (quote (x)))',
    '(map + (quote (1 . 2)))', '(apply + 1 2)', '(member 1 2)'
  ].each do |source|
    it "rejects invalid sequence operations: #{source}" do
      expect { runtime.evaluate(source) }.to raise_error(Scheme::Error)
    end
  end
end
