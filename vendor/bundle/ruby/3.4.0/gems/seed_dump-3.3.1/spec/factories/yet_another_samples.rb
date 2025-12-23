FactoryBot.define do
  factory :yet_another_sample do
    string   'string'
    text     'text'
    integer  42
    float    3.14
    decimal  2.72
    datetime DateTime.parse('July 4, 1776 7:14pm UTC')
    time     Time.parse('3:15am UTC')
    date     Date.parse('November 19, 1863')
    binary   'binary'
    boolean  false
  end
end
