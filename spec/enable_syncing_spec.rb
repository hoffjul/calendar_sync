require 'spec_helper'

describe 'enable syncing' do
  include Capybara::DSL

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

  def log_in
    visit '/'
    click_link 'Log in'
  end

  def enable_sync(space_name)
    visit '/spaces'
    click_link space_name
    fill_in 'Calendar URL', with: 'http://example.org/example.ics'
    select 'Meeting Room', from: 'Resource'
    click_button 'Sync Calendar'
  end
end
