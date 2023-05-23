require './lib/delivery_methods/microsoft_graph.rb'

ActionMailer::Base.add_delivery_method :microsoft_graph, MicrosoftGraph, location: '../../lib/delivery_methods/microsoft_graph.rb'
