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

  it 'ignores 422 errors, i.e. conflicting bookings on create' do
    RestClient.stub(:get) { double.as_null_object }
    Icalendar.stub(:parse) { [double(:calendar, events: [double(:event1).as_null_object,
      double(:event2).as_null_object])] }
    RestClient.stub(:post).with('ics1').and_raise('xyz')
    sync = double(:sync, bookings: double(:bookings, where: [])).as_null_object
    Synchronization.stub(all: [sync])
    cobot_client = double(:api_client)
    CobotClient::ApiClient.stub(new: cobot_client)
    cobot_client.stub(:create_booking).and_raise(RestClient::UnprocessableEntity)

    service.sync_all
  end

  it 'ignores 422 errors, i.e. conflicting bookings on update'
end
