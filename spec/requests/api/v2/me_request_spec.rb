require 'spec_helper'

describe 'Me API V2' do
  describe 'unauthorized current' do
    it 'Sends correct error code when no user present' do
      get '/api/v2/me'
      expect(response.response_code).to eq(401)
      expect(response.body.match('OAuth')).to be_present
      expect(response.headers['Content-Type'].match('json')).to be_present
      expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
      expect(response.headers['Access-Control-Request-Method']).to eq('*')
    end
  end

  describe 'authorized current' do
    before :each do
      create_doorkeeper_app
    end

    it "responds with all available attributes with full scoped token" do
      @token.update_attribute :scopes, OAUTH_SCOPES_S
      # token = Doorkeeper::AccessToken.create!(application_id: @application.id, resource_owner_id: @user.id, scopes: OAUTH_SCOPES_S)
      get "/api/v2/me", format: :json, access_token: @token.token
      result = JSON.parse(response.body)
      expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
      expect(result["user"]["name"]).to eq(@user.name)
      expect(result["user"]["secondary_emails"]).to eq([])
      expect(result["id"]).to eq(@user.id.to_s)
      expect(result["user"].is_a?(Hash)).to be_truthy
      expect(result["bike_ids"].is_a?(Array)).to be_truthy
      expect(result["memberships"].is_a?(Array)).to be_truthy
      expect(response.response_code).to eq(200)
    end

    it 'responds with all available attributes with full scoped token' do
      @token.update_attribute :scopes, OAUTH_SCOPES_S
      # token = Doorkeeper::AccessToken.create!(application_id: @application.id, resource_owner_id: @user.id, scopes: OAUTH_SCOPES_S)
      get '/api/v2/me', format: :json, access_token: @token.token
      expect(response.response_code).to eq(200)
      result = JSON.parse(response.body)
      expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
      expect(result['id']).to eq(@user.id.to_s)
      expect(result['user'].is_a?(Hash)).to be_truthy
      expect(result['bike_ids'].is_a?(Array)).to be_truthy
      expect(result['memberships'].is_a?(Array)).to be_truthy
    end

    it "doesn't include bikes if no bikes scoped" do
      token = Doorkeeper::AccessToken.create!(application_id: @application.id, resource_owner_id: @user.id)
      expect(token.scopes.to_s.match('read_bikes').present?).to be_falsey
      get '/api/v2/me', format: :json, access_token: token.token
      expect(response.response_code).to eq(200)
      result = JSON.parse(response.body)
      expect(result['id']).to eq(@user.id.to_s)
      expect(result['bike_ids'].present?).to be_falsey
    end

    it "doesn't include memberships if no memberships scoped" do
      token = Doorkeeper::AccessToken.create!(application_id: @application.id, resource_owner_id: @user.id)
      expect(token.scopes.to_s.match('read_organization_membership').present?).to be_falsey
      get '/api/v2/me', format: :json, access_token: token.token
      expect(response.response_code).to eq(200)
      result = JSON.parse(response.body)
      expect(result['id']).to eq(@user.id.to_s)
      expect(result['memberships'].present?).to be_falsey
    end

    it "doesn't include memberships if no memberships scoped" do
      get '/api/v2/me', format: :json, access_token: @token.token
      expect(response.response_code).to eq(200)
      result = JSON.parse(response.body)
      expect(result['id']).to eq(@user.id.to_s)
      expect(result['user'].present?).to be_falsey
    end
  end

  describe 'current/bikes' do
    before :each do
      create_doorkeeper_app
    end
    it "works if it's authorized" do
      @token.update_attribute :scopes, 'read_bikes'
      get '/api/v2/me/bikes', format: :json, access_token: @token.token
      # get '/api/v2/me/bikes', {}, 'Authorization' => "Basic #{Base64.encode64("#{@token.token}:X")}"
      result = JSON.parse(response.body)
      expect(result['bikes'].is_a?(Array)).to be_truthy
      expect(response.response_code).to eq(200)
    end
    it "403s if read_bikes_spec isn't in token" do
      get '/api/v2/me/bikes', format: :json, access_token: @token.token
      expect(response.response_code).to eq(403)
    end
  end
end
