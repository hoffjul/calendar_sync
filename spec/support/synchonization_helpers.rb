module SynchronizationHelpers
  def enable_sync(space_name, ics_url: 'http://example.org/example.ics')
    visit '/spaces'
    click_link space_name
    fill_in 'Calendar URL', with: ics_url
    select 'Meeting Room', from: 'Resource'
    click_button 'Sync Calendar'
  end

  def sync_ics(filename)
    stub_request(:get, 'http://example.org/example.ics')
      .to_return(body: File.read("spec/fixtures/#{filename}"))
    SyncService.new.sync_all
  end

  def stub_ics
    stub_request(:get, 'http://example.org/example.ics').to_return(
      body: File.read('spec/fixtures/example.ics'))
  end
end

RSpec.configure do |c|
  c.include SynchronizationHelpers
end
