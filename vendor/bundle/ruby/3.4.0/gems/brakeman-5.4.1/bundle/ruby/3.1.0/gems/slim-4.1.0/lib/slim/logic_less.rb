require 'slim'
require 'slim/logic_less/filter'
require 'slim/logic_less/context'

Slim::Engine.after Slim::Interpolation, Slim::LogicLess
