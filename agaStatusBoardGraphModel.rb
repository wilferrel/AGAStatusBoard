require 'rubygems'
require 'sinatra'
require 'json'
require 'time'
# require 'active_support'
require './agaURLCurlHelper'


def buildGraphForIssues(json)
  parsedJSON = JSON.parse(json)
  #Seperated Arrays
  completedIssues=parsedJSON["contents"]["completedIssues"]
  incompleteIssues=parsedJSON["contents"]["incompletedIssues"]
  #Create Graph Object
  jiraGraph= PanicGraphModel.new
  jiraGraph.graphTitle="Sprint- #{$jiraCurrentSprintTitle}"
  @completed_Hash_datapoints={"title" =>"Sprint 6", "value"=>completedIssues.count}
  jiraGraph.addADatapoint(@completed_Hash_datapoints)
  jiraGraph.addDataSequenceWithDatapoints("Completed","Green")
  @incompleted_Hash_datapoints={"title" =>"Sprint 6", "value"=>incompleteIssues.count}
  jiraGraph.addADatapoint(@incompleted_Hash_datapoints)
  jiraGraph.addDataSequenceWithDatapoints("Incomplete","Red")
  return jiraGraph.getStatusBoardGraphJSON
end

class PanicGraphModel
  attr_accessor :graphTitle, :hash_datasequences, :datasequenceHash, :datasequencesArray, :datapointsArray
  def initialize
    @graphTitle = ""
    #hash that describes the type of Datasequences *datasequences needs to be an Array of Hashes
    @graphHash={"title" =>"", "datasequences"=>[]} 
    #Hash used to layout datasequences
    @datasequenceHash={"title"=>"", "datapoints"=>[]}
    #number of different objects of comparison in graph
    @datasequencesArray = [] 
    #Array of number of datapoints for a given sequence
    @datapointsArray =[]    
  end
  #Will add a Datasequence Array Set
  def addDataSequenceWithDatapoints(title,color="")
    @datasequenceHash={"title"=>title,"color"=>color, "datapoints"=>@datapointsArray}
    @datasequencesArray.push(@datasequenceHash)
    @datapointsArray=Array.new 
  end 
  #Will add a Datapoint hash to Datapoint Array
  def addADatapoint(datapointHash)
    @datapointsArray.push(datapointHash)
  end
  
  #Will return final JSON
  def getStatusBoardGraphJSON
    @graphHash={"title" =>@graphTitle, "datasequences"=>@datasequencesArray} 
    @mainHashForStatusBoard={"graph" =>@graphHash}
    return @mainHashForStatusBoard.to_json
  end
  
end