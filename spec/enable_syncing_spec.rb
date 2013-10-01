require 'spec_helper'

describe 'enable syncing' do
  before(:each) do
    stub_cobot_user credentials: {token: 'token-123'},
      extra: {
        raw_info: {
          admin_of: [{space_subdomain: 'co-up', space_name: 'co.up'}]
        }
      }
    stub_cobot_resources 'co-up', [{name: 'Meeting Room'}]
    log_in
    stub_ics
  end

  it 'lets a space admin enable a space' do
    enable_sync 'co.up'
  end

  it 'shows an error when the url does not return an ics file' do
    stub_request(:get, 'http://example.com/invalid.csv').to_return(
      body: 'abc;xyz')
    enable_sync 'co.up', ics_url: 'http://example.com/invalid.csv'

    expect(page).to have_content('The URL you entered is not a valid calendar file.')
  end

  it 'lets a space admin disable a space' do
    enable_sync 'co.up'

    visit '/spaces/co-up'
    click_button 'Stop syncing'

    visit '/spaces/co-up'
    expect(page).to have_no_css('input[value=\'Stop syncing\']')
  end
end
