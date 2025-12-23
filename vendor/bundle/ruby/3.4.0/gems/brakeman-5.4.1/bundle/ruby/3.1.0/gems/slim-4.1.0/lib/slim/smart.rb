require 'slim'
require 'slim/smart/filter'
require 'slim/smart/escaper'
require 'slim/smart/parser'

Slim::Engine.replace Slim::Parser, Slim::Smart::Parser
Slim::Engine.after Slim::Smart::Parser, Slim::Smart::Filter
Slim::Engine.after Slim::Interpolation, Slim::Smart::Escaper
