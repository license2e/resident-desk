require 'base64'
require 'uri'
require 'net/http'

module DecodeDataURI

  def DecodeDataURI::decode_data_uri(uri)
    uri = URI.parse(uri) unless uri.kind_of? URI

    raise ArgumentError.new("Incorrect URI scheme, expected data:, got #{uri.scheme}") unless
      uri.scheme == 'data'

    # extract the media type and data
    uri.opaque =~ /^([^,]+)?,(.*)$/

    mediatype = $1
    data = $2

    # if the media is base64 encoded, set the flag and strip it
    if base64 = $1 =~ /^(.+);base64$/
      mediatype = $1
    end

    # decode
    if base64
      data = Base64.decode64(data)
    end

    return data, mediatype
  end
end