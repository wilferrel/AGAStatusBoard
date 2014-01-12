require 'net/http'

def callJira(url,username,pass)
  returnedJson= `curl -u #{username}:#{pass} -X GET  "#{url}"`
   return returnedJson
end

def callAppAnnie(url,apiToken)
  returnedJson= `curl -H "Authorization: bearer #{apiToken}" -X GET  "#{url}"`
  return returnedJson
end