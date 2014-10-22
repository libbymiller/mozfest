require 'faye'
require 'thin'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/cross_origin'
require 'serialport'
require 'json'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'pp'

$stdout.sync = true

DataMapper.setup(:default, 'sqlite3:///home/pi/mozfest/db/stalker_data.db')

class Device 
  include DataMapper::Resource
  property :id, Serial
  property :mac, String
  property :source, String
  property :timestamp, Integer
  property :image, String
  property :power, Integer
  property :associated, String
end

DataMapper.finalize
DataMapper.auto_upgrade!
Device.raise_on_save_failure = true

class MyApp < Sinatra::Base
  register Sinatra::CrossOrigin


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

  get '/canvas' do
    cross_origin
    puts "canvas"  
    erb :canvas
  end

  post '/metadata' do
    cross_origin
    request.body.rewind
    request_payload = JSON.parse request.body.read
    puts "=====got metadata====="
    pp request_payload
    #fixme
    z = request_payload["data"][0]["time"].to_i
    id = request_payload["data"][0]["id"]
    power = request_payload["data"][0]["power"].to_i
    nearest_power = request_payload["data"][0]["power"].to_i

    nearest_id = request_payload["data"][0]["id"]
    friend_ids = []
    source = request_payload["data"][0]["source"]


    request_payload["data"].each do |rq|
      friend_ids.push(rq["id"])
      if(nearest_power < rq["power"].to_i )
        nearest_power = rq["power"].to_i
        nearest_id = rq["id"]
      end
    end
    if(source=="mozdisplayer")
      puts "MOZ DISPLAYER"
      @devices = Device.all :mac => id
#                          :limit => 10,
#                          :order => 'timestamp desc'

      if(@devices)
        @devices.each do |d|
          puts d.mac
          puts d.image
          puts d.timestamp
          puts d.associated
          puts "publishing data for #{id}"
          client.publish('/foo', 'source' => d.source, 'image' => d.image, 'id' => d.mac, 'power' => d.power, 'friends' => d.associated)
        end
      else
        puts "no devices found for mac #{id}"
      end

    else
      files_sorted_by_time = Dir['notpublic/data/*.jpg'].sort_by {|_key, value| value}

      if(files_sorted_by_time!=nil && files_sorted_by_time.length > 10)
#     files_sorted_by_time = files_sorted_by_time.slice(-10,10)
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
        mf = min_file.gsub(/notpublic\//,"")

        if(minimum.abs < 10)
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
                         :timestamp => z,
                         :image => mf,
                         :power => nearest_power,
                         :associated => friend_ids
           pp device
           if(device.save)
             puts "ok, saved"
           else
             puts "not saved...."
           end
        end
      end
    end
  end

# these go initially in a different place, periodically deleted

  post '/image' do
    cross_origin
    puts "=====got image====="
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
#    ObjectSpace.each_object(File) do |f|
#      unless f.closed?
#        puts "This file is still open: %s: %d\n" % [f.path, f.fileno]
#      end
#    end

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
#                          :order => 'timestamp desc'

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


