# frozen_string_literal: true

module Rack::MiniProfilerRailsMethods
  def render_notification_handler(name, finish, start, name_as_description: false)
    return if !should_measure?

    description = name_as_description ? name : "Rendering: #{name}"
    current = Rack::MiniProfiler.current.current_timer
    node = current.add_child(description)
    duration = finish - start
    duration_ms = duration * 1000
    node.start -= duration
    node[:start_milliseconds] -= duration_ms
    node.record_time(duration_ms)

    children_duration = 0
    to_be_moved = { requests: [], sql: [], custom: {} }
    current.children.each do |child|
      next if child == node
      if should_move?(child, node)
        to_be_moved[:requests] << child
        children_duration += child[:duration_milliseconds]
      end
    end
    node[:duration_without_children_milliseconds] = duration_ms - children_duration
    to_be_moved[:requests].each { |req| current.move_child(req, node) }

    current.sql_timings.each do |sql|
      to_be_moved[:sql] << sql if should_move?(sql, node)
    end
    to_be_moved[:sql].each { |sql| current.move_sql(sql, node) }

    current.custom_timings.each do |type, timings|
      to_be_moved[:custom] = []
      timings.each do |custom|
        to_be_moved[:custom] << custom if should_move?(custom, node)
      end
      to_be_moved[:custom].each { |custom| current.move_custom(type, custom, node) }
    end
  end

  def should_measure?
    current = Rack::MiniProfiler.current
    current && current.measure
  end

  def should_move?(child, node)
    start = :start_milliseconds
    duration = :duration_milliseconds
    child[start] >= node[start] &&
    child[start] + child[duration] <= node[start] + node[duration]
  end

  def get_webpacker_assets_path
    if defined?(Webpacker) && Webpacker.try(:config)&.config_path&.exist?
      Webpacker.config.public_output_path.to_s.gsub(Webpacker.config.public_path.to_s, "")
    end
  end

  extend self
end
