class Status < ActiveRecord::Base
  require 'scr'

  attr_accessor :data

  def initialize
    @scr = Scr.instance
    @health_status = nil
    @data = Hash.new
    start_collectd
#    @collectd_base_dir = "/var/lib/collectd/"
    @datapath = set_datapath
    @metrics = available_metrics
  end

  def start_collectd
    cmd = @scr.execute(["collectd"])
    @timestamp = Time.now
  end

  def stop_collectd
    cmd = @scr.execute(["killall", "collectd"])
    @timestamp = nil
  end

  # set path of stored rrd files, default: /var/lib/collectd/$host.$domain
  def set_datapath(path=nil)
    default = "/var/lib/collectd/"
    unless path.nil?
      @datapath = path.chomp("/")
    else # set default path
      cmd = IO.popen("hostname")
      host = cmd.read
      cmd.close
      cmd = IO.popen("domainname")
      domainname = cmd.read
      cmd.close
      @datapath = "#{default}#{host.strip}.#{domainname.strip}"
    end
    return @datapath
  end

  def available_metrics
    metrics = Hash.new
    cmd = IO.popen("ls #{@datapath}")
    output = cmd.read
    cmd.close
    output.split(" ").each do |l|
      fp = IO.popen("ls #{@datapath}/#{l}")
      files = fp.read
      fp.close
      metrics["#{l}"] = { :rrds => files.split(" ")}
    end
    return metrics
  end

  def available_metric_files
    cmd = IO.popen("ls #{@datapath}..")
    lines = cmd.read.split "\n"
    cmd.close
    return lines
  end

  def determine_status
  end

  def draw_graph(heigth=nil, width=nil)
  end

  # creates several metrics for a defined period
  def collect_data(start=Time.now, stop=Time.now, data = nil)
    result = Hash.new
    unless @timestamp.nil? # collectd not started
        case data
        when nil # all metrics
          @metrics.each_pair do |m, n|
            @metrics["#{m}"][:rrds].each do |rrdb|
              result["#{rrdb}".chomp(".rrd")] = fetch_metric("#{m}/#{rrdb}", start, stop)
            end
            @data["#{m}"] = result
            result = Hash.new
          end
        else
          data.each do |d|
            @metrics.each_pair do |m, n|
              if m.include?(d)
                @metrics["#{m}"][:rrds].each do |rrdb|
                result["#{rrdb}".chomp(".rrd")] = fetch_metric("#{m}/#{rrdb}", start, stop)
              end
              @data["#{m}"] = result
              result = Hash.new
            end
          end
        end
      end
    end
    return @data
  end

  # creates one metric for defined period
  def fetch_metric(rrdfile, start=Time.now, stop=Time.now)#, heigth=nil, width=nil)
    sum = 0.0
    counter = 0
    result = Hash.new#Array.new
    cmd = IO.popen("rrdtool fetch #{@datapath}/#{rrdfile} AVERAGE "\
                                     "--start #{start} --end #{stop}")
    output = cmd.read
    cmd.close

    output = output.gsub(",", ".") # translate 1,234e+07 to 1.234e+07
    lines = output.split "\n"
    lines[0].each do |l|
      if l =~ /\D*/
        labels = l.split " "
        collumn = 1
        labels.each do
          lines.each do |l|
            if l =~ /\d*:\D*/  ####
              pair = l.split " "
              unless pair[collumn].include?("nan") # no valid measurement
                sum += pair[collumn].to_f
                counter += 1
              end
            end
          end
          result[labels[collumn-1]] = sum/(counter) unless counter == 0
          sum, counter = 0.0, 0
          collumn += 1
        end
      end
    end
    return result
  end
end
