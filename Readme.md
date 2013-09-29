This app syncs calendars to the Cobot booking calendar. You need to provide an `.ics` feed URL and a resource on Cobot. This app will then create bookings on that resource for each of the events on the calendar.

# Deployment

Needs a postgres database configured via ENV[DATABASE_URL].

Set ENV[RAVEN_DSN] for error tracking via getsentry.com.

Set up a cron job that runs `bundle exec rake sync_calendars` every hour.

