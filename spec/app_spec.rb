require 'spec_helper'

describe 'health endpoint' do
  it 'returns status 200' do
    get '/health'

    expect(last_response.status).to eql(200)
  end
end
