# frozen_string_literal: true

require 'fileutils'
require 'yaml'

module Schedule
  class Config
    CONFIG_DIR = "#{Dir.home}/.schedule-cli/"
    DEFAULT_CONFIG = {
      calendars: ['primary'],
      day: {
        start: 8,
        end: 18,
      },
      defaults: {
        day_offset: 'next weekday',
        day_buffer: 1,
        duration: 30,
        align_to: 15,
      },
      events: {
        call: { duration: 30 },
        coffee: { duration: 60 },
      },
    }.freeze

    def self.file(*args)
      File.join(CONFIG_DIR, *args)
    end

    def self.config_file
      file('config.yml')
    end

    def self.setup!
      FileUtils.mkdir_p CONFIG_DIR
      File.write(config_file, YAML.dump(DEFAULT_CONFIG)) unless File.file?(config_file)
    end

    def self.value(*args)
      values.dig *args
    end

    def self.values
      @values ||= YAML.load(File.read(config_file)) # rubocop:disable Security/YAMLLoad
    end
  end
end
