# frozen_string_literal: true

require 'dotenv'
require 'aws-sdk-s3'

client = Aws::S3::Client.new(
  access_key_id: ENV['DO_SPACES_KEY'],
  secret_access_key: ENV['DO_SPACES_SECRET'],
  endpoint: ENV['DO_SPACES_END_POINT'],
  force_path_style: false,
  region: ENV['DO_SPACES_REGION']
)

resource = Aws::S3::Resource.new(client: client)
bucket = resource.bucket('db-backups-envixo')

date = Date.today.to_s
prefix = "invoice_web/2023-02-14"

bucket.objects(prefix: prefix).each do |obj|
  puts obj.key
end