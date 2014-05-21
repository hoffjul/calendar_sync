require 'spec_helper'

describe 'syncing a calendar' do
  before(:each) do
    stub_cobot_user credentials: {token: 'token-123'},
      extra: {raw_info: {admin_of: [{space_subdomain: 'co-up', space_name: 'co.up'}]}}
    stub_cobot_resources 'co-up', [{id: 'meeting-room', name: 'Meeting Room'}]
    stub_request(:post, %r{api/resources/meeting-room/bookings}).to_return(
      body: {id: 'booking-123'}.to_json)
    stub_request(:get, %r{api/bookings}).to_return(body: [].to_json)
    log_in
    stub_ics
    enable_sync 'co.up', ics_url: 'http://example.org/example.ics'
  end

  it 'adds new bookings' do
    stub_request(:get, %r{api/bookings}).to_return(body: [
      {from: "2013/09/30 09:00:00 +0000", to: "2013/09/30 10:00:00 +0000", resource: {id: "meeting-room"}}
    ].to_json)

    sync_ics 'example.ics'

    expect(a_request(:post, 'https://co-up.cobot.me/api/resources/meeting-room/bookings')
      .with(
        headers: {'Authorization' => 'Bearer token-123'},
        body: {
          title: 'Important meeting',
          from: '2013-09-30T08:00:00+00:00',
          to: '2013-09-30T09:00:00+00:00'})).to have_been_made
  end

  it 'adds all day events' do
    sync_ics 'all_day.ics'

    expect(a_request(:post, 'https://co-up.cobot.me/api/resources/meeting-room/bookings')
      .with(
        headers: {'Authorization' => 'Bearer token-123'},
        body: {
          title: 'Long meeting',
          from: '2013-10-17T00:00:00+00:00',
          to: '2013-10-19T23:59:59+00:00'})).to have_been_made
  end

  it 'removes removed bookings' do
    Timecop.travel 2013, 9, 20 do
      stub_request(:delete, %r{api/bookings})
      sync_ics 'example.ics'
      sync_ics 'empty.ics'

      expect(a_request(:delete, 'https://co-up.cobot.me/api/bookings/booking-123')
        .with(headers: {'Authorization' => 'Bearer token-123'})).to have_been_made
    end
  end

  it 'does not remove past bookings' do
    sync_ics 'example.ics'
    sync_ics 'empty.ics'

    expect(a_request(:delete, 'https://co-up.cobot.me/api/bookings/booking-123')).to_not have_been_made
  end

  it 'updates changed bookings' do
    stub_request(:put, %r{api/bookings}).to_return(body: '{}')
    sync_ics 'example.ics'
    sync_ics 'changed.ics'

    expect(a_request(:put, 'https://co-up.cobot.me/api/bookings/booking-123')
      .with(
        body: {
          from: '2013-09-30T09:00:00+00:00',
          to: '2013-09-30T10:00:00+00:00',
          title: 'Very important meeting'
        },
        headers: {'Authorization' => 'Bearer token-123'})
    ).to have_been_made
  end

  it 'does not update unchanged bookings' do
    stub_request(:put, %r{api/bookings}).to_return(body: '{}')
    2.times { sync_ics 'example.ics' }

    expect(a_request(:put,
      'https://co-up.cobot.me/api/bookings/booking-123')).to_not have_been_made
  end

  it 'does not add bookings that would conflict with existing bookings' do
    stub_request(:get, 'https://co-up.cobot.me/api/bookings?from=2012-01-01T11:00:00%2B00:00&to=2012-01-01T14:30:00%2B00:00').to_return(body: [
      {from: "2012/01/01 12:00:00 +0000", to: "2012/01/01 14:00:00 +0000", resource: {id: "meeting-room"}}
    ].to_json)
    sync_ics 'conflicts.ics'

    expect(a_request(:post, 'https://co-up.cobot.me/api/resources/meeting-room/bookings')).to_not have_been_made
  end

  it 'does not try to get bookings if calendar is empty' do
    sync_ics 'empty.ics'

    expect(a_request(:get, %r{/api/bookings})).to_not have_been_made
  end

  it 'stops syncing if getting the bookings returns 404, i.e. the space has been deleted' do
    stub_request(:get, %r{api/bookings}).to_return(status: 404)

    2.times { sync_ics 'example.ics' }

    expect(a_request(:get, %r{/api/bookings})).to have_been_made.once
  end
end
