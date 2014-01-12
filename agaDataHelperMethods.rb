def getAllIssuesStats(allIssuesArray)
  totalClosedIssues= allIssuesArray.count { |issue| issue["statusId"].eql? "6" }
  totalOpenIssues= allIssuesArray.count { |issue| issue["statusId"].eql? "1" }
  totalResolvedIssues= allIssuesArray.count { |issue| issue["statusId"].eql? "5" }
  totalInProgressIssues= allIssuesArray.count { |issue| issue["statusId"].eql? "3" }
  totalReopenedIssues= allIssuesArray.count { |issue| issue["statusId"].eql? "4" }
  totalCodeReviewIssues= allIssuesArray.count { |issue| issue["statusId"].eql? "10001" } 
  tempHash={"Open"=>totalOpenIssues,"In Progress"=>totalInProgressIssues,"Code Review"=>totalCodeReviewIssues,"Resolved"=>totalResolvedIssues,"Closed"=>totalClosedIssues,"Reopened"=>totalReopenedIssues }
  #Check if any Hash Key is 0 and if so boot out
  tempHash.each do |key, value|
    if value == 0
        tempHash.except(key)
    end
  end 
  return tempHash
end

def getAllIssuesForProject(username,password,rapidViewID)
  $jiraCurrentProject=rapidViewID
  jiraURL= "https://#{$jiraDomain}/rest/greenhopper/1.0/xboard/plan/backlog/data.json?rapidViewId=#{rapidViewID}"
  jiraJSONReturn=callJira(jiraURL,username,password)
  if valid_json(jiraJSONReturn)
    return jiraJSONReturn
  else
    raise "Check your Jira Credentials and Rapid View ID"
  end
end
  
  
def getCurrentActiveSprint()
  response=getAllIssuesForProject($username,$password,$jiraCurrentProject)
  parsedJSON = JSON.parse(response)
  jiraAllSprintsArray=parsedJSON["sprints"]
  jiraAllSprintsArray.each do |sprint|
    if sprint["state"].eql? "ACTIVE"
         $jiraCurrentSprint=sprint["id"]
         $jiraCurrentSprintTitle=sprint["name"]
         break
    end
  end
  return $jiraCurrentSprint
end

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

def jenkinsJob_Order(client, job)
  status = client.job.get_current_build_status(job)

  case status
    when "failure"
      1
    when "unstable"
      2
    when "running"
      3
    when "not_run"
      4
    when "aborted"
      5
    when "success"
      6
    else
      7
  end
  return status
end

def valid_json(json_)  
  JSON.parse(json_)  
  return true  
rescue JSON::ParserError  
  return false  
end 


def pagerDutySearchForUserAvatar(userID)
  usersResponse=HTTParty.get("https://#{$companyURL}/api/v1/users",:headers => { "Authorization" => "#{$pagerDutyToken}"},:query =>{:limit=>"100"})
  usersResponse=usersResponse["users"]
  usersResponse.each do |singleUser|
    if singleUser["id"] == userID
      return singleUser["avatar_url"]
    end
  end


end
