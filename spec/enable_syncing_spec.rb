require 'spec_helper'

describe 'enable syncing' do
  before(:each) do
    stub_cobot_user credentials: {token: 'token-123'},
      admin_of: [{space_subdomain: 'co-up', space_name: 'co.up'}]
    stub_cobot_resources 'co-up', [{name: 'Meeting Room'}]
  end

  it 'lets a space admin log in and enable a space' do
    log_in

    enable_sync 'co.up'
  end

  it 'lets a space admin disable a space' do
    log_in
    enable_sync 'co.up'

    visit '/spaces/co-up'
    click_button 'Stop syncing'

    visit '/spaces/co-up'
    expect(page).to have_no_css('input[value=\'Stop syncing\']')
  end
end
