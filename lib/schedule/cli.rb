# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'

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

    desc 'availability type|duration offset', 'print availability table'
    method_option :html, type: :boolean, default: false
    method_option :debug, type: :boolean, default: false
    def availability(type = nil, *offset_string)
      config = Config.value(:defaults)
      if /\A\d+\z/.match?(type)
        config[:duration] = type.to_i
      else
        event_config = Config.value(:events, type&.to_sym)
        config = config.deep_merge(event_config) if event_config.present?
      end
      if offset_string.present?
        config[:day][:offset] = parse_offset offset_string.join(' ')
      elsif config[:day][:offset].is_a?(String)
        config[:day][:offset] = parse_offset config[:day][:offset]
      end
      puts config.to_s if options.debug?
      slots = Schedule::Calendar.new(config).free_slots
      print_with_options "#{format_free_slots(slots)}<br/>#{config[:footer]}"
    end

    desc 'config', 'open config file in default editor'
    def config
      system("${EDITOR:-${VISUAL:-vi}} '#{Config.config_file}'")
    end

    desc 'reset', 'reset config and auth tokens'
    def reset
      system("rm -r #{Config::CONFIG_DIR}")
    end

    desc 'version', 'print gem version'
    def version
      puts Schedule::VERSION
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
      return "<b style='color: red;'>No free slots!</b>" unless slots.present?
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
