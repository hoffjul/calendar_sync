require 'spec_helper'

describe SyncService, '#sync_all' do
  it 'continues after an error' do
    sync1 = double(:sync1, ics_url: 'ics1')
    sync2 = double(:sync2, ics_url: 'ics2')
    RestClient.stub(:get).with('ics1').and_raise('xyz')
    Synchronization.stub(all: [sync1, sync2])

    expect(RestClient).to receive(:get).with('ics2')

    SyncService.new.sync_all
  end
end
