# frozen_string_literal: true

require 'thor'
require 'nokogiri'
require 'chronic'

require 'schedule/calendar'

module Schedule
  class Cli < Thor
    package_name 'Schedule'
    default_task :availability

    def initialize(*args, **kwargs)
      Config.setup!
      super
    end

    desc 'availability type', 'print availability table'
    method_option :html, type: :boolean, default: false
    method_option :debug, type: :boolean, default: false
    def availability(type = nil, *offset_string)
      config = Config.values.slice(:calendars, :day).merge(Config.value(:defaults))
      if /\A\d+\z/.match(type)
        config[:duration] = type.to_i
      else
        config.merge!(Config.value(:events, type&.to_sym) || {})
      end
      if offset_string.present?
        config[:day_offset] = parse_offset offset_string.join(' ')
      elsif config[:day_offset].is_a?(String)
        config[:day_offset] = parse_offset config[:day_offset]
      end
      puts "#{config}" if options.debug?
      slots = Schedule::Calendar.new(config).free_slots
      print_with_options format_free_slots(slots)
    end

    desc 'config', 'open config file in default editor'
    def config
      system("${EDITOR:-${VISUAL:-vi}} '#{Config.config_file}'")
    end

    private

    def parse_offset(string)
      (Chronic.parse(string, context: :future).to_date - Date.today).to_i
    end

    def print_with_options(string)
      formatted = options.html? ? string : plain_text(string)
      puts formatted
    end

    def plain_text(html)
      document = Nokogiri::HTML.parse(html)
      document.css('br').each { |node| node.replace("\n") }
      document.text
    end

    def format_free_slots(slots)
      dates = Hash.new { |h, k| h[k] = [] }
      slots.each do |(s, e)|
        dates[s.to_date] << "#{s.strftime('%-l:%M %p')} to #{e.strftime('%-l:%M %p')}"
      end
      dates.map do |date, times|
        "<u><b>#{date.strftime('%A %B %-e')}</b></u><br/>#{times.join('<br/>')}"
      end.join('<br/>')
    end
  end
end
