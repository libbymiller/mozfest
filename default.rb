require 'faye'
require 'thin'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/cross_origin'
#require 'serialport'
require 'json'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'pp'
require 'time'

$stdout.sync = true

DataMapper.setup(:default, 'sqlite3:///home/pi/mozfest/db/stalker_data.db')


class Device 
  include DataMapper::Resource
  property :id, Serial
  property :mac, String
  property :source, String
  property :epochtime, Integer
  property :image, String
  property :power, Integer
  property :associated, Text
  property :company, String
  property :aps, Text
end

DataMapper.finalize
DataMapper.auto_upgrade!
Device.raise_on_save_failure = true
Rack::Utils.multipart_part_limit = 0

class MyApp < Sinatra::Base
  register Sinatra::CrossOrigin

  #oui = {}
  client = nil
  set :static, true
  set :public_dir, 'public'

  before do
    client = Faye::Client.new('http://10.0.0.200:9292/faye')
    
#    client.subscribe('/foo') do |message|
#      puts "got message"
#      puts message.inspect
#    end

  end

  get '/' do
    cross_origin
    puts "stalker"  
    erb :stalker
  end

  get '/exclusions' do
    cross_origin
    puts "exclusions"  
    exclusions = File.read("exclusions.txt")
    exclusions
  end

  get '/canvas' do
    cross_origin
    puts "canvas"  
    erb :canvas
  end

  post '/metadata' do
   begin
    cross_origin
    puts "++++++++++++"
    request.body.rewind
    rb = request.body.read.encode('UTF-8','UTF-8', :invalid => :replace)
    rb = rb.gsub(/\n/,"")
    rb = rb.gsub(/\r/,"")
    request_payload = JSON.parse rb
    result_arr = request_payload["data"].sort_by{|m| m["power"].to_i.abs}
    puts "=====got metadata====="
    pp result_arr
    #fixme
    z = result_arr[0]["time"].to_i
    id = result_arr[0]["id"]
    power = result_arr[0]["power"].to_i
    nearest_power = result_arr[0]["power"].to_i

    nearest_id = result_arr[0]["id"]
    friend_ids = []
    source = result_arr[0]["source"]
    company = result_arr[0]["company"]
    aps = result_arr[0]["aps"]
    # ensure we have the nearest
    result_arr.each do |rq|
      if(nearest_power < rq["power"].to_i )
        nearest_power = rq["power"].to_i
        company = rq["company"]
        aps = rq["aps"]
        nearest_id = rq["id"]
      end
    end
    if(company)
      company = company.gsub(/\W+/,"")
    end
    puts "company is #{company} ..."

    # collate "friends"
    result_arr.each do |rq|
      if(rq[id]!=nearest_id)
        friend_ids.push(rq["id"])
      end
    end

      files_sorted_by_time = Dir['notpublic/data/*.jpg'].sort_by {|_key, value| value}

      if(files_sorted_by_time!=nil && files_sorted_by_time.length > 10)
        minimum = 10000 
        min_file = nil
        files_sorted_by_time.each do |k|
          f = k.gsub(/notpublic\/data\//,"")
          f = f.gsub(/.jpg/,"")
          diff = (z.to_i - f.to_i)
#          puts "payload time is #{z} image time is #{f}"
 #         puts "diff #{diff.abs} minimum.abs #{minimum.abs} result #{diff.abs < minimum.abs} "
          if(diff.abs < minimum.abs)
            minimum = diff
            min_file = k
          end
        end

        if( min_file && minimum.abs < 10)
           mf = min_file.gsub(/notpublic\//,"")
           begin
             puts "copying notpublic/#{mf} to public/#{mf}"
             FileUtils.cp("notpublic/#{mf}", "public/#{mf}")
           rescue Exception=>e
             puts "problem copying image #{e}"
           end
           puts "minimum.abs is #{minimum.abs}"
           puts "saving item"
           device = Device.new :mac     => nearest_id,
                         :source      => source,
                         :epochtime => z,
                         :image => mf,
                         :power => nearest_power,
                         :associated => friend_ids,
                         :company => company,
                         :aps => aps
           pp device
           if(device.save)
             puts "ok, saved"
           else
             puts "not saved...."
           end
        end
      end

#.....
      puts "POWER ABS #{power.abs}"
      if( power.abs < 41) # needs testing
        puts "MOZ DISPLAYER"
        images = []
        @devices = Device.all :mac => id,
                            :limit => 10,
                            :order => [:epochtime.desc],
                            :unique => true
#                            :order => 'epochtime'
#                            :order => 'epochtime desc'

        if(@devices)
          faye_data = []
          associated = []
          mac = ""
          power = ""
          company = ""
          epochtime = ""
          aps = ""
          @devices.each do |d|
            if(!images.include?(d.image))
              images.push(d.image)
              aa = JSON.parse(d.associated)
              aa.each do |a|
                ob_a = a[0..-6]
                ob_a = "#{ob_a}XX:XX"
                associated.push(ob_a)
              end
              mac =  d.mac
              puts d.image
              puts d.epochtime
              power = d.power
              aps = d.aps
              epochtime =  Time.at(d.epochtime.to_i)
              puts d.associated
              company = d.company
            end
          end
          associated = associated.uniq
          puts "publishing data for #{id}!!!!"
          ob_mac = mac[0..-6]
          ob_mac = "#{ob_mac}XX:XX"
          faye_data.push('images' => images.join(","), 'id' => ob_mac, 'power' => power, 'friends' => associated.join(","), 'company' => company, 'time'=> epochtime, 'aps'=> aps)
#          faye_data.push('images' => images.join(","), 'id' => id, 'power' => power, 'friends' => associated.join(","), 'company'=>'', 'time'=> epochtime)
          if(ob_mac!="XX:XX") #ugh
            client.publish('/foo', faye_data)
          end
        else
          puts "no devices found for mac #{id}"
        end
      end
#....

    #end
    rescue Exception => e
       puts "\n\n\n\n"
       puts "METADATA ERROR"
       puts e
       puts "\n\n\n\n"
    end

  end

# these go initially in a different place, periodically deleted

  post '/image' do
   begin
    cross_origin
    puts "=====got image====="
    pp params
    name =  params[:name]
    my_file =  params[:my_file]

    unless params[:my_file] &&
           (tmpfile = params[:my_file][:tempfile]) 
      @error = "No file selected"
    end
    STDERR.puts "Uploading file, original name #{name}"
    directory = "notpublic/data"
    path = File.join(directory, name+".jpg")
    File.open(path, 'wb') do |f|
      while chunk = tmpfile.read(65536)
        f.write(chunk)
      end
      tmpfile.close
    end
    puts "done"
#    ObjectSpace.each_object(File) do |f|
#      unless f.closed?
#        puts "This file is still open: %s: %d\n" % [f.path, f.fileno]
#      end
#    end

    rescue Exception => e
      puts "\n\n\n"
      puts "PROBLEM with image"
      puts "\n\n\n"
      puts e
    end

    "Upload complete\n"
  end

  get '/devices' do
    @devices = Device.all
    @devices.each do |d|
      puts d.mac
      puts d.image
      puts d.associated
    end
    "ok!"

  end

  get '/device/:mac' do
    mac = params[:mac]
#    @devices = Device.all
    @devices = Device.all :mac => mac
#                          :limit => 10,
#                          :order => 'epochtime desc'

    if(@devices)
      @devices.each do |d|
        puts d.mac
        puts d.image
        puts d.associated
      end
    else
      puts "no devices found for mac #{mac}"
    end
    "fine!"
#    erb :device
  end

end


