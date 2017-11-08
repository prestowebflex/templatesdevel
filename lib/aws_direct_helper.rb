# class to generate the necessary form data to allow direct s3 uploads
require "securerandom"
# require 'fog'

# # create a connection
# CONNECTION = Fog::Storage.new({
#   :provider                 => 'AWS',
#   :aws_access_key_id        => ENV['S3_KEY'],
#   :aws_secret_access_key    => ENV['S3_SECRET']
# });

# # First, a place to contain the glorious details
# DIRECTORY = CONNECTION.directories.get('yourapp-public-files');

class AwsDirectHelper
	# include ::CarrierWaveDirect::Uploader
 	
 	FILENAME_WILDCARD = "${filename}"


	def initialize 
		# @fog_directory = fog_directory
		@bucket = "yourapp-public-files"
		@aws_access_key_id = ENV['S3_KEY']
		@aws_secret_access_key = ENV['S3_SECRET']
		@region = "ap-southeast-2"
	end

	attr_reader :bucket, :aws_access_key_id, :aws_secret_access_key, :region

	alias :fog_directory :bucket

	def generate_form_values
		{
			url: "https://#{bucket}.s3-#{region}.amazonaws.com",
			form_values: 		{  
									policy: policy,
									key: key,
									acl: acl,
									"X-Amz-Algorithm" => algorithm,
									"X-Amz-Credential" => credential,
									"X-Amz-Date" => date,
									"X-Amz-Signature" => signature,
									success_action_status: 201
								}

		}
	end

    def acl
      'public-read'
    end

    def policy(options = {}, &block)
      options[:expiration] ||= upload_expiration
      options[:min_file_size] ||= min_file_size
      options[:max_file_size] ||= max_file_size

      @date ||= Time.now.utc.strftime("%Y%m%d")
      @timestamp ||= Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
      @policy ||= generate_policy(options, &block)
    end

    def upload_expiration
    	1.hour
    end

    def min_file_size
    	1024 #1.kilobyte
    end

    def max_file_size
    	524288000 #500.megabytes
    end

    def date
      @timestamp ||= Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
    end

    def algorithm
      'AWS4-HMAC-SHA256'
    end

    def credential
      @date ||= Time.now.utc.strftime("%Y%m%d")
      "#{aws_access_key_id}/#{@date}/#{region}/s3/aws4_request"
    end

    def clear_policy!
      @policy = nil
      @date = nil
      @timestamp = nil
    end

   def signature
      OpenSSL::HMAC.hexdigest(
        'sha256',
        signing_key,
        policy
      )
    end    


    def guid
      @guid ||= SecureRandom.uuid
    end

    def key
    	"uploads/#{guid}/#{FILENAME_WILDCARD}"
    end

    private

    def generate_policy(options)
      conditions = []

      # conditions << ["starts-with", "$utf8", ""] if options[:enforce_utf8]
      conditions << ["starts-with", "$key", key.sub(/#{Regexp.escape(FILENAME_WILDCARD)}\z/, "")]
      conditions << {'X-Amz-Algorithm' => algorithm}
      conditions << {'X-Amz-Credential' => credential}
      conditions << {'X-Amz-Date' => date}
      conditions << ["starts-with", "$Content-Type", ""]
      conditions << {"bucket" => fog_directory}
      conditions << {"acl" => acl}
      conditions << {"success_action_status" => "201"}

      conditions << ["content-length-range", options[:min_file_size], options[:max_file_size]]

      yield conditions if block_given?

      Base64.encode64(
        {
          'expiration' => (Time.now + options[:expiration]).utc.iso8601,
          'conditions' => conditions
        }.to_json
      ).gsub("\n","")
    end


    def signing_key(options = {})
      @date ||= Time.now.utc.strftime("%Y%m%d")
      #AWS Signature Version 4
      kDate    = OpenSSL::HMAC.digest('sha256', "AWS4" + aws_secret_access_key, @date)
      kRegion  = OpenSSL::HMAC.digest('sha256', kDate, region)
      kService = OpenSSL::HMAC.digest('sha256', kRegion, 's3')
      kSigning = OpenSSL::HMAC.digest('sha256', kService, "aws4_request")

      kSigning
    end


end