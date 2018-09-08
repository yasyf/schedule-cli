# frozen_string_literal: true

require 'active_support/core_ext/date'
require 'active_support/core_ext/numeric/time'

require 'launchy'
require 'parallel'

require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'schedule/availability_range'
require 'schedule/config'

module Schedule
  class Calendar
    CLIENT_ID = '913320886860-hml2g9fmellq668ljv4od42jntkmuefd.apps.googleusercontent.com'
    TOKENS_PATH = Config.file('tokens.yml')
    SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY
    OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

    def initialize(options)
      @service = Google::Apis::CalendarV3::CalendarService.new.tap do |service|
        service.authorization = authorize!
      end
      @options = options
    end

    def free_slots
      center = Date.today + @options[:day][:offset].days
      (start, end_), events = get_events_in_range(center, @options[:day][:buffer])

      range = AvailabilityRange.new(
        start.beginning_of_day,
        end_.end_of_day,
        min_delay: @options[:min_delay],
        day_start: @options[:day][:start],
        day_end: @options[:day][:end],
      )
      events.each do |event|
        range.mark!(
          parse_event_datetime(event.start, date_transformer: :beginning_of_day),
          parse_event_datetime(event.end, date_transformer: :end_of_day),
        )
      end
      range.free_ranges(**@options.slice(:duration, :align_to))
    end

    private

    def parse_event_datetime(datetime, date_transformer:)
      if datetime.date_time.present?
        datetime.date_time
      else
        Date.parse(datetime.date).send(date_transformer).to_datetime
      end
    end

    def get_events_in_range(center, buffer)
      is_weekend = center.saturday? || center.sunday?
      events = []

      back_current = center
      buffer_back = 0
      while buffer_back < buffer
        back_current -= 1.day
        if !is_weekend && (back_current.saturday? || back_current.sunday?)
          events << Google::Apis::CalendarV3::Event.new(
            start: Google::Apis::CalendarV3::EventDateTime.new(date: back_current.to_s),
            end: Google::Apis::CalendarV3::EventDateTime.new(date: back_current.to_s),
          )
        else
          buffer_back += 1
        end
      end

      forward_current = center
      buffer_forward = 0
      while buffer_forward < buffer
        forward_current += 1.day
        if !is_weekend && (forward_current.saturday? || forward_current.sunday?)
          events << Google::Apis::CalendarV3::Event.new(
            start: Google::Apis::CalendarV3::EventDateTime.new(date: forward_current.to_s),
            end: Google::Apis::CalendarV3::EventDateTime.new(date: forward_current.to_s),
          )
        else
          buffer_forward += 1
        end
      end

      events.concat get_events_for_dates(back_current, forward_current)

      [[back_current, forward_current], events.uniq]
    end

    def get_events_for_dates(from, to)
      Parallel.map(@options[:calendars], in_threads: @options[:calendars].length) do |calendar|
        @service.list_events(
          calendar,
          single_events: true,
          time_min: from.beginning_of_day.iso8601,
          time_max: to.end_of_day.iso8601,
        ).items
      end.flatten.select { |e| e.transparency == 'opaque' }
    end

    def authorize!
      token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKENS_PATH)
      client_id = Google::Auth::ClientId.new(CLIENT_ID, '')
      authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
      authorizer.get_credentials(:default) || begin
        url = authorizer.get_authorization_url(base_url: OOB_URI)
        puts 'Redirecting to Google for authorization...'
        Launchy.open(url) { puts "Open this URL in your browser:\n#{url}\n\n" }
        print 'Code: '
        code = STDIN.gets
        authorizer.get_and_store_credentials_from_code(user_id: :default, code: code, base_url: OOB_URI)
      end
    end
  end
end
