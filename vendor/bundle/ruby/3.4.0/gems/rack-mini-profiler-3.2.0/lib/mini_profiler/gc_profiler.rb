# frozen_string_literal: true

class Rack::MiniProfiler::GCProfiler

  def initialize
    @ignore = []
    @ignore << @ignore.__id__
  end

  def object_space_stats
    stats = Hash.new(0).compare_by_identity
    ids = Hash.new.compare_by_identity

    @ignore << stats.__id__
    @ignore << ids.__id__

    ObjectSpace.each_object { |o|
      begin
        stats[o.class] += 1
        ids[o.__id__] = o if Integer === o.__id__
      rescue NoMethodError
        # protect against BasicObject
      end
    }

    @ignore.each do |id|
      if ids.delete(id)
        klass = ObjectSpace._id2ref(id).class
        stats[klass] -= 1
      end
    end

    result = { stats: stats, ids: ids }
    @ignore << result.__id__

    result
  end

  def diff_object_stats(before, after)
    diff = {}.compare_by_identity
    after.each do |k, v|
      diff[k] = v - before[k]
    end
    before.each do |k, v|
      diff[k] = 0 - v unless after.has_key?(k)
    end

    diff
  end

  def analyze_strings(ids_before, ids_after)
    result = {}
    ids_after.each do |id, _|
      obj = ObjectSpace._id2ref(id)
      if String === obj && !ids_before.include?(obj.object_id)
        result[obj] ||= 0
        result[obj] += 1
      end
    end
    result
  end

  def analyze_growth(ids_before, ids_after)
    new_objects = 0
    memory_allocated = 0

    ids_after.each do |id, _|
      if !ids_before.include?(id) && obj = ObjectSpace._id2ref(id)
        # this is going to be version specific (may change in 2.1)
        size = ObjectSpace.memsize_of(obj)
        memory_allocated += size
        new_objects += 1
      end
    end

    [new_objects, memory_allocated]
  end

  def analyze_initial_state(ids_before)
    memory_allocated = 0
    objects = 0

    ids_before.each do |id, _|
      if obj = ObjectSpace._id2ref(id)
        # this is going to be version specific (may change in 2.1)
        memory_allocated += ObjectSpace.memsize_of(obj)
        objects += 1
      end
    end

    [objects, memory_allocated]
  end

  def profile_gc(app, env)

    # for memsize_of
    require 'objspace'

    # clean up before
    GC.start
    stat          = GC.stat
    prev_gc_state = GC.disable
    stat_before   = object_space_stats
    b             = app.call(env)[2]
    b.close if b.respond_to? :close
    stat_after = object_space_stats
    # so we don't blow out on memory
    prev_gc_state ? GC.disable : GC.enable

    diff                          = diff_object_stats(stat_before[:stats], stat_after[:stats])
    string_analysis               = analyze_strings(stat_before[:ids], stat_after[:ids])
    new_objects, memory_allocated = analyze_growth(stat_before[:ids], stat_after[:ids])
    objects_before, memory_before = analyze_initial_state(stat_before[:ids])

    body = []

    body << "
Overview
--------
Initial state: object count: #{objects_before}
Memory allocated outside heap (bytes): #{memory_before}

GC Stats:
--------
#{stat.map { |k, v| "#{k} : #{v}" }.sort!.join("\n")}

New bytes allocated outside of Ruby heaps: #{memory_allocated}
New objects: #{new_objects}
"

    body << "
ObjectSpace delta caused by request:
-----------------------------------\n"
    diff.to_a.delete_if { |_k, v| v == 0 }.sort_by! { |_k, v| v }.reverse_each do |k, v|
      body << "#{k} : #{v}\n"
    end

    body << "\n
ObjectSpace stats:
-----------------\n"

    stat_after[:stats].to_a.sort_by! { |_k, v| v }.reverse_each do |k, v|
      body << "#{k} : #{v}\n"
    end

    body << "\n
String stats:
------------\n"

    string_analysis.to_a.sort_by! { |_k, v| -v }.take(1000).each do |string, count|
      body << "#{count} : #{string}\n"
    end

    [200, { 'Content-Type' => 'text/plain' }, body]
  ensure
    prev_gc_state ? GC.disable : GC.enable
  end
end
