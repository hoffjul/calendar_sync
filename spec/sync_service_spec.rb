require 'spec_helper'

describe SyncService, '#sync_all' do
  let(:service) { SyncService.new }

  it 'continues after an error' do
    sync1 = double(:sync1, ics_url: 'ics1').as_null_object
    sync2 = double(:sync2, ics_url: 'ics2').as_null_object
    RestClient.stub(:get).with('ics1').and_raise('xyz')
    Synchronization.stub(all: [sync1, sync2])

    expect(RestClient).to receive(:get).with('ics2')

    service.sync_all
  end
end
