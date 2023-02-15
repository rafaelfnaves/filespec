# frozen_string_literal: true

require 'aws-sdk-s3'
require 'dotenv'
require 'pry'

Dotenv.load

client = Aws::S3::Client.new(
  access_key_id: ENV['DO_SPACES_KEY'],
  secret_access_key: ENV['DO_SPACES_SECRET'],
  endpoint: ENV['DO_SPACES_END_POINT'],
  force_path_style: false,
  region: ENV['DO_SPACES_REGION']
)
resource = Aws::S3::Resource.new(client: client)
bucket = resource.bucket(ENV['DO_SPACES_BUCKET'])

folder = "invoice_web"
date = Time.now.strftime("%Y-%m-%d")
prefix = "#{folder}/#{date}"

begin
  bucket.objects(prefix: prefix).each do |obj|
    file = obj.key.gsub("#{folder}/", "")
    client.get_object(
      bucket: ENV['DO_SPACES_BUCKET'],
      key: obj.key,
      response_target: "./tmp/#{file}"
    )
  end
rescue Exception => error
  puts "Error on sync spaces => #{error.message}"
end

unless file.nil?
  system("")
end