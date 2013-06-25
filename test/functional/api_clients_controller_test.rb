require 'test_helper'

class ApiClientsControllerTest < ActionController::TestCase
  setup do
    @api_client = api_clients(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:api_clients)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create api_client" do
    assert_difference('ApiClient.count') do
      post :create, api_client: { method: @api_client.method, url: @api_client.url }
    end

    assert_redirected_to api_client_path(assigns(:api_client))
  end

  test "should show api_client" do
    get :show, id: @api_client
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @api_client
    assert_response :success
  end

  test "should update api_client" do
    put :update, id: @api_client, api_client: { method: @api_client.method, url: @api_client.url }
    assert_redirected_to api_client_path(assigns(:api_client))
  end

  test "should destroy api_client" do
    assert_difference('ApiClient.count', -1) do
      delete :destroy, id: @api_client
    end

    assert_redirected_to api_clients_path
  end
end
