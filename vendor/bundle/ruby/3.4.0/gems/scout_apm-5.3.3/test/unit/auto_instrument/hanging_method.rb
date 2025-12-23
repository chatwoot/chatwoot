class TestController < ApplicationController
end

def hanging_method
  Test.first
end