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
    
    root = params[:routing]
    if root == nil
      render ErrorResult.error(404, 2, "format or internal error") and return
    end
    
    @routing = Routing.new(root)
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

    @routes = Routes.find

    respond_to do |format|
      format.html { render :xml => @routes.to_xml( :root => "routes", :dasherize => false ) }
      format.xml { render :xml => @routes.to_xml( :root => "routes", :dasherize => false ) }
      format.json { render :json => @routes.to_json }
    end
  end

  def index
   show
  end

end
