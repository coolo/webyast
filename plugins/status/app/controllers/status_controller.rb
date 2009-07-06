include ApplicationHelper

require 'scr'

class StatusController < ApplicationController
  before_filter :login_required

  public
  # POST /status
  # POST /status.xml
  def create
  end

  # GET /status
  # GET /status.xml
  def index
    show
  end

  # GET /status/1
  # GET /status/1.xml
  def show
    unless permission_check("org.opensuse.yast.system.status.read")
      render ErrorResult.error(403, 1, "no permission") and return
    else
      @status = Status.new
      @status.collect_data("11:13,07/03/2009", "11:14,07/03/2009", %w{cpu memory disk})

      respond_to do |format|
        format.html { render :xml => @status.data.to_xml, :location => "none" } #return xml only
        format.xml  { render :xml => @status.data.to_xml, :location => "none" }
        format.json { render :json => @status.data.to_xml, :location => "none" }
      end
    end
  end

  # PUT /status/1
  # PUT /status/1.xml
  def update
    unless permission_check("org.opensuse.yast.system.status.read")
      render ErrorResult.error(403, 1, "no permission") and return
    else
      @status = Status.new
      @status.collect_data(params[:start], params[:stop], params[:data])
      #logger.debug "SHOW: #{@status.inspect}"

      respond_to do |format|
        format.html { render :xml => @status.data.to_xml, :location => "none" } #return xml only
        format.xml  { render :xml => @status.data.to_xml, :location => "none" }
        format.json { render :json => @status.data.to_xml, :location => "none" }
      end
    end
  end
end