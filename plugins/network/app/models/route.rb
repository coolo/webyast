# = Routing model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class Route

  # default gateway
  attr_accessor :via,
		:id

  private

  public

  def initialize(kwargs)
    @via = kwargs["via"]
  end

  # fills route instance with data from YaPI.
  #
  # +warn+: YaPI implements default only.
  def Route.find( which )
    response = YastService.Call("YaPI::NETWORK::Read")
    ret = Route.new(response["routes"][which])
    ret.id = which
    return ret
  end

  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set).
  def save
    settings = {
      @id => { 'via'=>@via },
    }
    YastService.Call("YaPI::NETWORK::Write",{"route" => settings})
    # TODO success or not?
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.route do
      xml.via @via
    end
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
