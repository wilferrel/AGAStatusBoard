require 'rubygems'
require 'sinatra'
require 'json'
require 'time'
require 'date'
require './agaURLCurlHelper'
require './agaStatusBoardGraphModel'
require './agaDataHelperMethods'
require 'jenkins_api_client'
require 'httparty'

set :public_folder, 'public'

#Index Page
get '/' do
"Welcome to AGAStatusBoard"
end


######################JIRA############################
#This Service will return Completed and Incomplete Jira's for Specific Sprint
#Params: username,password,RapidViewId,SprintId
get '/JiraCompleteAndIncomplete' do
  keys= params[:splat]
  $username=params["username"]
  $password=params["password"]
  $jiraCurrentProject=params["rapidViewId"]
  $jiraDomain=params["jiraDomain"]
  if $username.nil? || $password.nil? || $jiraCurrentProject.nil?
    "Missing parameters"
  else
    sprintID=getCurrentActiveSprint()
    jiraURL= "https://#{$jiraDomain}/rest/greenhopper/1.0/rapid/charts/sprintreport?rapidViewId=#{$jiraCurrentProject}&sprintId=#{sprintID}"
    jiraJSONReturn= callJira(jiraURL,$username,$password)
    "#{buildGraphForIssues(jiraJSONReturn)}"
  end
end

#Gets All Issues grouped by Status
get '/getJiraAllDifferentIssues' do
  keys= params[:splat]
  $username=params["username"]
  $password=params["password"]
  $jiraDomain=params["jiraDomain"]
  $jiraCurrentProject=params["rapidViewId"]
  graphTitle=params["graphTitle"]
  response=getAllIssuesForProject($username,$password,$jiraCurrentProject)
  parsedJSON = JSON.parse(response)
  allJiraIssuesArray=parsedJSON["issues"]
  # return "#{getAllIssuesStats(allJiraIssuesArray)}"
  allJiraIssuesHash=getAllIssuesStats(allJiraIssuesArray)
  #Create Graph Object
  jiraGraph= PanicGraphModel.new
  jiraGraph.graphTitle=graphTitle
  #Open Issues
  openIssueHash={"title" =>"Issue", "value"=>allJiraIssuesHash["Open"]}
  jiraGraph.addADatapoint(openIssueHash)
  jiraGraph.addDataSequenceWithDatapoints("Open","Red")
  #In Progress Issues
  inProgressIssueHash={"title" =>"Issue", "value"=>allJiraIssuesHash["In Progress"]}
  jiraGraph.addADatapoint(inProgressIssueHash)
  jiraGraph.addDataSequenceWithDatapoints("In Progress","Orange")
  #Code Review Issues
  codeReviewIssueHash={"title" =>"Issue", "value"=>allJiraIssuesHash["Code Review"]}
  jiraGraph.addADatapoint(codeReviewIssueHash)
  jiraGraph.addDataSequenceWithDatapoints("Code Review","Blue")
  #Resolved Issues
  resolvedIssueHash={"title" =>"Issue", "value"=>allJiraIssuesHash["Resolved"]}
  jiraGraph.addADatapoint(resolvedIssueHash)
  jiraGraph.addDataSequenceWithDatapoints("Resolved","Green")
  #Closed Review Issues
  closedIssueHash={"title" =>"Issue", "value"=>allJiraIssuesHash["Closed"]}
  jiraGraph.addADatapoint(closedIssueHash)
  jiraGraph.addDataSequenceWithDatapoints("Closed","Blue")
  #Reopened Issues
  reopenedIssueHash={"title" =>"Issue", "value"=>allJiraIssuesHash["Reopened"]}
  jiraGraph.addADatapoint(reopenedIssueHash)
  jiraGraph.addDataSequenceWithDatapoints("Reopened","Yellow")
  return jiraGraph.getStatusBoardGraphJSON 
end
##########################################################

######################AppAnnie############################
#Get App Downloads for give range must be within 60 days
get '/AppAnnieDownloadsForRange' do
  apiToken=params["apiToken"]
  accountID=params["accountID"]
  appId=params["appID"]
  endDate= params["endDate"]
  startDate= params["startDate"]
  if startDate>endDate
    raise "Start Date is after the End Date supplied"
  end
  appAnnieURL= "https://api.appannie.com/v1/accounts/#{accountID}/apps/#{appId}/sales?break_down=date+iap&start_date=#{startDate}&end_date=#{endDate}&currency=USD&countries=US&page_index=0"
  parsedJSON= HTTParty.get(appAnnieURL,:headers => { "Authorization" => " bearer #{apiToken}"})
  if !parsedJSON.success?
    raise "Check AppAnnie Credentials, Start and End Date (yyyy-mm-dd) and try again"
  end
  allAppSales=parsedJSON["sales_list"]
  #Create Graph Object
  appAnnieGraph= PanicGraphModel.new
  appAnnieGraph.graphTitle="iOS Sales"
  allAppSales.reverse!.each do |appSale|
    #Get Date for x Label
    date = Date.parse appSale["date"]
    #Add Sales datasequences
    salesHash={"title" =>"Issue", "value"=>appSale["units"]["app"]["downloads"]}
    appAnnieGraph.addADatapoint(salesHash)
    appAnnieGraph.addDataSequenceWithDatapoints(date.strftime("%b-%e"))
  end
  "#{appAnnieGraph.getStatusBoardGraphJSON}"
end

#Get App Downloads for current Month
get '/AppAnniePast30' do
  apiToken=params["apiToken"]
  accountID=params["accountID"]
  appId=params["appID"]
  endDate= Date.today.strftime("%Y-%m-%d")
  startDate=Date.today.strftime("%Y-%m-01")
  appAnnieURL= "https://api.appannie.com/v1/accounts/#{accountID}/apps/#{appId}/sales?break_down=date+iap&start_date=#{startDate}&end_date=#{endDate}&currency=USD&countries=US&page_index=0"
  parsedJSON= HTTParty.get(appAnnieURL,:headers => { "Authorization" => " bearer #{apiToken}"})
  if !parsedJSON.success?
    raise "Check AppAnnie Credentials and try again"
  end
  allAppSales=parsedJSON["sales_list"]
  #Create Graph Object
  appAnnieGraph= PanicGraphModel.new
  appAnnieGraph.graphTitle="iOS Downloads #{Time.now.strftime("%B %Y")}"
  allAppSales.reverse!.each do |appSale|
    #Get Date for x Label
    date = Date.parse appSale["date"]
    #Add Sales datasequences
    salesHash={"title" =>"Issue", "value"=>appSale["units"]["app"]["downloads"]}
    appAnnieGraph.addADatapoint(salesHash)
    appAnnieGraph.addDataSequenceWithDatapoints(date.strftime("%b-%e"))
  end
  "#{appAnnieGraph.getStatusBoardGraphJSON}"
end
##########################################################

######################Jenkins#############################
get '/JenkinsJobs' do
  keys= params[:splat]
  serverIP=params["jenkinsIP"]
  username=params["username"]
  password=params["password"]
  client = JenkinsApi::Client.new(:server_ip => serverIP,
                                :username => username, :password => password)
                                
  if File.exist?(file_name)
    File.delete(file_name)
  end
  file = File.new("./public/jenkins.html" || "jenkins.html", "w+")
  file.puts "<table>"

  client.job.list_all.sort { |x, y| jenkinsJob_Order(client, x) <=> jenkinsJob_Order(client, y) }.each do |job|
    status = client.job.get_current_build_status(job)
    file.puts "<tr><td width='50'><img width='32' height='32' src='http://www.merowing.info/wp-content/uploads/jenkins/#{status}@2x.png'/></td><td>#{job}</td></tr>"
  end
  file.puts "</table>"

  file.close()
  redirect '/jenkins.html' 
end

get '/JenkinsNoLogin' do
  keys= params[:splat]
  serverIP=params["jenkinsIP"]
  username=""
  password=""
  client = JenkinsApi::Client.new(:server_ip => serverIP,
                                :username => username, :password => password)
  file = File.new("./public/jenkins.html" || "jenkins.html", "w+")
  file.puts "<table>"

  client.job.list_all.sort { |x, y| jenkinsJob_Order(client, x) <=> jenkinsJob_Order(client, y) }.each do |job|
    status = client.job.get_current_build_status(job)
    file.puts "<tr><td width='50'><img width='32' height='32' src='http://www.merowing.info/wp-content/uploads/jenkins/#{status}@2x.png'/></td><td>#{job}</td></tr>"
  end
  file.puts "</table>"
  file.close()
  redirect '/jenkins.html' 
end
##########################################################

get '/PGDutySched' do
  $companyURL=params["companyURL"]
  $pagerDutyToken=params["token"]
  $scheduleId=params["scheduleID"]
  startDate=Date.today
  endDate=Date.today >> 1
  scheduleResponse= HTTParty.get("https://#{$companyURL}/api/v1/schedules/#{$scheduleId}/entries",:headers => { "Authorization" => "#{$pagerDutyToken}"},:query =>{:since=>"#{startDate.strftime("%Y/%m/%d")}", :until=>"#{endDate.strftime("%Y/%m/%d")}"})
  if !scheduleResponse.success?
    raise "Check PagerDuty Credentials and Schedule ID and try again"
  end
  #Create HTML Table for Schedule
  file = File.new("./public/pagerDutySchedule.html" || "pagerDutySchedule.html", "w+")
  file.puts "<table>"
  
  scheduleResponse["entries"].each do |user|
    userFullName=user["user"]["name"]
    userId=user["user"]["id"]
    userStartDate=DateTime.parse(user["start"])
    userEndDate=DateTime.parse(user["end"])
    userAvatar= pagerDutySearchForUserAvatar(userId)
    file.puts "<tr>"
    file.puts "<td width='10' class='userIcon'><img width='32' height='32' src='#{userAvatar}'/></td>"
    file.puts "<td width='150' class='userFullName' >#{userFullName} </td>"
    file.puts "<td width='100' class='startEndDates' >#{userStartDate.strftime("%-m/%-d")}-#{userEndDate.strftime("%-m/%-d")} </td>"
    # file.puts "<td width='100' class='startEndTimes' >#{userStartDate.strftime("%l:%M %p")} - #{userEndDate.strftime("%l:%M %p")} </td>"
    file.puts "</tr>"
  end
  file.puts "</table>"
  file.close()
  redirect '/pagerDutySchedule.html'
end


get '/iosReview' do
  result =  HTTParty.get('http://reviewtimes.shinydevelopment.com/sb_trend30.json')
  averageTime=0
  resultTwo=JSON.parse(result)
  resultTwo=resultTwo["graph"]["datasequences"] 
  iosTimes=resultTwo[0]
  iosTimes["datapoints"].each do |dataPoints|
    if dataPoints["value"] > averageTime
      averageTime=dataPoints["value"].round
    end
  end
    @reviewDays = "#{averageTime}"
    erb :reviews
end






