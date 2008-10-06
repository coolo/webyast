require "scr"

class YastModulesController < ApplicationController

  before_filter :login_required

  require 'yastModule'
  private

  def init_modules (checkPolicy)
    @yastModules = Hash.new
    if (!checkPolicy or
        polkit_check( "org.opensuse.yast.webservice.read-yastmodulelist", self.current_account.login) == 0 )
       YastModule.all.each do |d|
         begin
            yastModule = YastModule.new d
            @yastModules[yastModule.id] = yastModule
         rescue # Don't fail on non-existing service. Should be more specific.
         end
       end
    else
       yastModule = YastModule.new ""
       yastModule.error_id = 1
       yastModule.error_string = "no permission"
       @yastModules[yastModule.id] = yastModule
    end
  end

  def respond data
    STDERR.puts "Respond #{data.class}"
    if data
      respond_to do |format|
	format.xml do
	  render :xml => data.to_xml
	end
	format.json do
	  render :json => data.to_json
	end
	format.html do
	  render
	end
      end
    else
      render :nothing => true, :status => 404 unless @yast_modules # not found
    end
  end
  public

  def index
    init_modules true #check policy
    respond @yastModules
  end

  def show
    id = params[:id]
    idPolicy = id.tr_s('_', '-')
    idPolicy = idPolicy.chomp
    idPolicy = idPolicy.downcase
    idPolicy = "org.opensuse.yast.webservice.read-yastmodule-" + idPolicy
    if (polkit_check( "org.opensuse.yast.webservice.read-yastmodule", self.current_account.login) == 0 or
        polkit_check( idPolicy, self.current_account.login) == 0 )
       init_modules false #check no policy
       @yastModule = @yastModules[id]
       @yastModule.commands #evaluate commands
    else
       @yastModule = YastModule.new ""
       @yastModule.error_id = 1
       @yastModule.error_string = "no permission"
    end

    respond @yastModule
  end


  def run
    id = params[:id]
    @cmdRet = Hash.new
    idPolicy = id.tr_s('_', '-')
    idPolicy = idPolicy.chomp
    idPolicy = idPolicy.downcase
    idPolicy = "org.opensuse.yast.webservice.run-yastmodule-" + idPolicy
    if (polkit_check( "org.opensuse.yast.webservice.run-yastmodule", self.current_account.login) == 0 or
        polkit_check( idPolicy, self.current_account.login) == 0 )
       init_modules false #check no policy
       @yastModule = @yastModules[id]
       @yastModule.commands #evaluate commands

       if request.post?
         #execute command

         if params["hash"] != nil
           #checking if the command is hosted in a own Hash
           params["hash"].each do |name,value|
              puts "Split hash #{name}:#{value}"
              params[name] = value
           end
         end
      
         cmdLine = "LANG=en.UTF-8 /sbin/yast2 #{params[:id]} #{params[:command]}"
         found = false
         @yastModule.commands.each do |cname,option|
           if cname == params["command"]
             found = true
             command = @yastModule.commands[cname]
             if command != nil
               command["options"].each do |name,option|
                 if params[name.to_s] != nil
                   if option["type"] == "string" 
                     if !params[name.to_s].empty? 
                       cmdLine += " #{name}=\"#{params[name.to_s]}\""
                     end
                   else 
                     if option["type"] == nil
                       cmdLine += " #{name}"
                     else
                        cmdLine += " #{name}=#{params[name.to_s]}"
                     end
                   end
                 end
               end
             end
             @cmdRet = Scr.execute(cmdLine)
           end
         end
         if !found
           STDERR.puts "command #{params[:command]} not found"
           @cmdRet["exit"] = 2
           @cmdRet["stderr"] = "command #{params[:command]} not found"
           @cmdRet["stdout"] = ""
         end
       else
         # no POST request

         idPolicy = "org.opensuse.yast.webservice.read-yastmodule-" + idPolicy
         if (polkit_check( "org.opensuse.yast.webservice.read-yastmodule", self.current_account.login) == 0 or
             polkit_check( idPolicy, self.current_account.login) == 0 )
            respond @yastModule
            return
         else
            STDERR.puts "no POST request"
            @cmdRet[:exit] = 2
            @cmdRet[:stderr] = "no POST request"
            @cmdRet[:stdout] = ""
         end
       end
    else #no right
       @cmdRet[:exit] = 1
       @cmdRet[:stderr] = "no permission"
       @cmdRet[:stdout] = ""
    end

    respond_to do |format|
       format.xml do
          render :xml => @cmdRet.to_xml
       end
       format.json do
          render :json => @cmdRet.to_json
       end
       format.html do
          render :file => "#{RAILS_ROOT}/app/views/yast_modules/results.html.erb"
       end
    end
  end
end
