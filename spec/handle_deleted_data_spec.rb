require 'spec_helper'

describe 'handling a deleted resource' do
  before(:each) do
    stub_cobot_user credentials: {token: 'token-123'},
      extra: {raw_info: {admin_of: [{space_subdomain: 'co-up', space_name: 'co.up'}]}}
    stub_cobot_resources 'co-up', [{id: 'meeting-room', name: 'Meeting Room'}]
    stub_request(:post, %r{api/resources/meeting-room/bookings}).to_return(
      body: {}.to_json, status: 404)
    log_in
    stub_ics
    enable_sync 'co.up', ics_url: 'http://example.org/example.ics'
  end

  it 'stops syncing' do
    sync_ics 'example.ics'
    sync_ics 'example.ics'

    expect(a_request(:post, 'https://co-up.cobot.me/api/resources/meeting-room/bookings'))
      .to have_been_made.once
  end
end
