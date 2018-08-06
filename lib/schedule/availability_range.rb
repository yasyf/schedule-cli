# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'

module Schedule
  class AvailabilityRange
    def initialize(start, end_, day_start:, day_end:, min_delay:, granularity: 5.minutes)
      @start = start
      @granularity = granularity
      @slots = Array.new(n_slots(start, end_)) do |i|
        dt = slot_to_datetime(i)
        ((dt - DateTime.now).days >= min_delay.hours) &&
          (dt.hour > day_start || (dt.hour == day_start && !dt.minute.zero?)) &&
          (dt.hour < day_end || (dt.hour == day_end && dt.minute.zero?))
      end
    end

    def mark!(start, end_)
      slot_range(start, end_).each do |i|
        @slots[i] = false
      end
    end

    def free_ranges(align_to:, duration:)
      ranges = []
      current_free = false

      @slots.each_with_index do |free, i|
        if current_free
          next if free
          ranges.last << i
          current_free = false
        else
          next unless free
          ranges << [i - 1]
          current_free = true
        end
      end

      ranges.map do |(s, e)|
        start = Time.at((slot_to_datetime(s).to_time.to_f / align_to.minutes).ceil * align_to.minutes)
        end_ = Time.at((slot_to_datetime(e).to_time.to_f / align_to.minutes).floor * align_to.minutes)
        (end_ - start) < duration.minutes ? nil : [start, end_]
      end.compact
    end

    private

    def slot_range(start, end_)
      n_slots(@start, start)..n_slots(@start, end_)
    end

    def n_slots(start, end_)
      ((end_.to_time - start.to_time) / @granularity.to_f).ceil
    end

    def slot_to_datetime(slot)
      (@start.to_time + (slot * @granularity)).to_datetime
    end
  end
end
