class ApiClientsController < ApplicationController
  # GET /api_clients
  # GET /api_clients.json
  def index
    @api_clients = ApiClient.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @api_clients }
    end
  end

  # GET /api_clients/1
  # GET /api_clients/1.json
  def show
    @api_client = ApiClient.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @api_client }
    end
  end

  # GET /api_clients/new
  # GET /api_clients/new.json
  def new
    @api_client = ApiClient.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @api_client }
    end
  end

  # GET /api_clients/1/edit
  def edit
    @api_client = ApiClient.find(params[:id])
  end

  # POST /api_clients
  # POST /api_clients.json
  def create
    @input = params[:api_client]
    @errors = nil
    
    if @input['url'] =~ /.xml/ 
      @errors = "Only JSON is supported"
    else
      @api_response = api_call(@input['method'],@input['url'])
      if @input['url'] =~ /client_authorize/
        if @api_response.is_a? Net::HTTPSuccess
          cookies['access_id'] = JSON.parse(@api_response.body)['response']['access_id']
          cookies['access_secret'] = JSON.parse(@api_response.body)['response']['access_secret']
        end
      end
    end

    @api_client = ApiClient.new
    # @api_client = ApiClient.new(params[:api_client])

    # format.html {redirect_to(:show), notice: 'This is the response.'}
    render action: "new"
    # respond_to do |format|
    #   if @api_client.save
    #     format.html { redirect_to @api_client, notice: 'Api client was successfully created.' }
    #     format.json { render json: @api_client, status: :created, location: @api_client }
    #   else
    #     format.html { render action: "new" }
    #     format.json { render json: @api_client.errors, status: :unprocessable_entity }
    #   end
    # end
    # respond_with(params[:api_client])
  end

  # PUT /api_clients/1
  # PUT /api_clients/1.json
  def update
    @api_client = ApiClient.find(params[:id])

    respond_to do |format|
      if @api_client.update_attributes(params[:api_client])
        format.html { redirect_to @api_client, notice: 'Api client was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @api_client.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /api_clients/1
  # DELETE /api_clients/1.json
  def destroy
    @api_client = ApiClient.find(params[:id])
    @api_client.destroy

    respond_to do |format|
      format.html { redirect_to api_clients_url }
      format.json { head :no_content }
    end
  end
end
