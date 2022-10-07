[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; 
 $source = 'https://cybercnsagentupdates.s3.amazonaws.com/agents/2.0.72/cybercnsagent.exe?AWSAccessKeyId=AKIA56PW5R2HOF3CKDHH&Signature=zKOM2jvr%2B%2BmkKqqFBdM1v%2FtN5nI%3D&Expires=1665167608'
$destination = 'cybercnsagent.exe'
Invoke-WebRequest -Uri $source -OutFile $destination
 ./cybercnsagent.exe -c 05dfa9a4-aca0-4caa-a543-5531b58c52e8 -a 05dfa9a4-aca0-4caa-a543-5531b58c52e8 -s 542b6d4b-ff50-4976-822b-5cc5dd446085 -b radersolutions.mycybercns.com -i LightWeight
