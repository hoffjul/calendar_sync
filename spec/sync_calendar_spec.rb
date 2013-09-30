require 'spec_helper'

describe 'syncing a calendar' do
  before(:each) do
    stub_cobot_user credentials: {token: 'token-123'},
      admin_of: [{space_subdomain: 'co-up', space_name: 'co.up'}]
    stub_cobot_resources 'co-up', [{id: 'meeting-room', name: 'Meeting Room'}]
  end

  it 'adds new bookings' do
    stub_request(:post, %r{api/resources/meeting-room/bookings})
    stub_request(:get, 'http://example.org/example.ics')
      .to_return(body: File.read('spec/fixtures/example.ics'))

    log_in
    enable_sync 'co.up', ics_url: 'http://example.org/example.ics'
    SyncService.new.sync_all

    expect(a_request(:post, 'https://co-up.cobot.me/api/resources/meeting-room/bookings')
      .with(
        headers: {'Authorization' => 'Bearer token-123'},
        body: {
          title: 'Important meeting',
          from: '2013-09-30T08:00:00+00:00',
          to: '2013-09-30T09:00:00+00:00'})).to have_been_made
  end

  it 'removes removed bookings'

  it 'updates changed booings'
end
