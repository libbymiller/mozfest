require 'faye'
require 'thin'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/cross_origin'
require 'serialport'
require 'json'

$stdout.sync = true


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
    require 'pp'
    pp request_payload
    #fixme
    z = request_payload["data"][0]["time"].to_i
    id = request_payload["data"][0]["id"]
    power = request_payload["data"][0]["power"].to_i
    nearest_power = request_payload["data"][0]["power"].to_i
    nearest_id = request_payload["data"][0]["id"]
    friend_ids = []
    source = request_payload["source"]
    request_payload["data"].each do |rq|
      friend_ids.push(rq["id"])
      if(nearest_power < rq["power"].to_i )
        nearest_power = rq["power"].to_i
        nearest_id = rq["id"]
      end
    end
    files_sorted_by_time = Dir['public/data/*.jpg'].sort_by {|_key, value| value}

    if(files_sorted_by_time!=nil && files_sorted_by_time.length > 10)
#     files_sorted_by_time = files_sorted_by_time.slice(-10,10)
      minimum = 10000 
      min_file = nil
      files_sorted_by_time.each do |k|
        f = k.gsub(/public\/data\//,"")
        f = f.gsub(/.jpg/,"")
        diff = (z.to_i - f.to_i)
#       puts "diff #{diff.abs} minimum.abs #{minimum.abs} result #{diff.abs < minimum.abs} "
        if(diff.abs < minimum.abs)
          minimum = diff
          min_file = k
        end
      end
      mf = min_file.gsub(/public\//,"")
      puts "minimum.abs is #{minimum.abs}"
      if(minimum.abs < 10)
        puts "publishing min #{minimum} min_file #{min_file}"
        client.publish('/foo', 'source' => source, 'image' => mf, 'id' => nearest_id, 'power' => nearest_power, 'friends' => friend_ids)
      end
    end
  end

  post '/image' do
    cross_origin
    name =  params[:name]
    my_file =  params[:my_file]

    unless params[:my_file] &&
           (tmpfile = params[:my_file][:tempfile]) 
      @error = "No file selected"
    end
    STDERR.puts "Uploading file, original name #{name}"
    directory = "public/data"
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

end


