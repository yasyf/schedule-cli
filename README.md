# Schedule

This gem allows you to quickly insert your calendar availability to any plain (or rich) text field. It connects with a single Google account but can pull appointments from various calendars. At Karuna, we have this hooked up to an [Alfred](https://www.alfredapp.com/) workflow.

## Installation

```bash
$ gem install schedule
```

## Usage

Run `schedule availability` to get your default availability table, which shows slots for a 30 minute meeting in a 3-day span centered on the weekday following today. Weekends are not considered as open slots unless the center date (`offset`) is a weekend.

The command can optionally be passed two arguments. The first is either the name of a named event (see below), or a number of minutes to specify a duration. The second is a string (such as "next wednesday") which specifies the center of the range to be scheduled over.

The command defaults to outputting plain text, but is much more useful when in HTML mode (pass the `--html` flag). This HTML can then be converted to RTF, e.g. using `schedule availability --html | textutil -stdin -format html -convert rtf -stdout`.

## Config

The following configuration flags are available. The YAML config file can be edited by running `schedule config`.

- `calendars` is a list of Calendar IDs to pull appointments from.
- `day` has two keys, `start` and `end`, which respectively indicate the earliest and latest times an event can be held in a day.
- `defaults` contains a bunch of options that are applied to events by default, but can be overridden by named events in the `events` list.

  - `align_to` gives the number of minutes to align each event slot to. Defaults to 15.
  - `day_offset` gives the default offset (center) for a span of days over which an event can be scheduled. Defaults to "next weekday", and can be any simple string describing a relative date.
  - `day_buffer` gives the number of days on either side of the center to be considered for scheduling events. Defaults to 1.
  - `duration` gives the number of minutes an event should last for
  - `min_delay` gives the number of hours in the future that an event must be scheduled after

- `footer` is an HTML string that is inserted after the table. This is used to include something like a Calendly link.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/karuna-health/schedule.
