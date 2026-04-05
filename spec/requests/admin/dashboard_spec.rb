# spec/requests/admin/dashboard_spec.rb
require 'rails_helper'

RSpec.describe 'Admin::Dashboard', type: :request do
  it 'returns http success' do
    get '/admin/dashboard'
    expect(response).to have_http_status(:success)
  end
end
