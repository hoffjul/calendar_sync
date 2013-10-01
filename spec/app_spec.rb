require 'spec_helper'

describe 'health endpoint' do
  it 'returns status 200' do
    get '/health'

    expect(last_response.status).to eql(200)
  end

  it 'renders help' do
    get '/help'

    expect(last_response.status).to eql(200)
  end

  it 'requires a login' do
    get '/spaces/123'

    expect(last_response.status).to eql(302)
    expect(last_response['Location']).to eql('http://example.org/')
  end

  it 'logs me out' do
    stub_cobot_user
    log_in

    click_link 'Log out'

    expect(page).to have_content('Log in')
    expect(page).to have_no_content('Log out')
  end
end
