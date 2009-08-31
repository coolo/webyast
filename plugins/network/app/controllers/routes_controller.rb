# = Routing controller
# Provides access to hostname settings for authenticated users.
# Main goal is checking permissions.
class RoutesController < ApplicationController

  before_filter :login_required

  # Sets hostname settings. Requires write permissions for network YaPI.
  def update
    unless permission_check( "org.opensuse.yast.modules.yapi.network.write")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    
    root = params[:routes]
    if root == nil
      render ErrorResult.error(404, 2, "format or internal error") and return
    end
    
    @routing = Route.new(root)
    @routing.save
    render :show
  end

  # See update
  def create
    update
  end

  # Shows hostname settings. Requires read permission for network YaPI.
  def show
    
    unless permission_check( "org.opensuse.yast.modules.yapi.network.read")
      render ErrorResult.error( 403, 1, "no permission" ) and return
    end

    @route = Route.find(params[:id])

    respond_to do |format|
      format.html { render :xml => @route.to_xml( :root => "route", :dasherize => false ) }
      format.xml { render :xml => @route.to_xml( :root => "route", :dasherize => false ) }
      format.json { render :json => @route.to_json }
    end
  end

  def index
   show
  end

end
