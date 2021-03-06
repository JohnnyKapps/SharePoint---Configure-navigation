Clear-Host

Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

function GetClientContext($url, $user, $password) {
     $context = New-Object Microsoft.SharePoint.Client.ClientContext($url) 
     $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($user, $password) 
     $context.Credentials = $credentials
     return $context
}

function DeleteOldNavigation (){
	$topNodes = $context.Web.Navigation.TopNavigationBar;
	$context.Load($topNodes);
	$context.ExecuteQuery();
	for ($ii = $topNodes.Count - 1; $ii -ge 0; $ii--)
	{
		Write-Host "Removendo " $topNodes[$ii].Title 
		$topNodes[$ii].deleteObject();
		$context.ExecuteQuery();
	}
}

function AddNavigation(){
	Write-Host "Configurando o menu superior..." -ForegroundColor Yellow
	$topNodes = $context.Web.Navigation.TopNavigationBar;	
	$templateXml = [xml](get-content $templateFile)
	
	foreach($header in $templateXml.Navigation.Header){
		$OutterNavigationNode = New-Object Microsoft.SharePoint.Client.NavigationNodeCreationInformation 
		$OutterNavigationNode.Title = $header.attributes['Title'].value
		$OutterNavigationNode.Url = $header.attributes['Address'].value
		$OutterNavigationNode.AsLastNode = $true
		$topNode = $topNodes.Add($OutterNavigationNode)
		$Context.Load($topNode)
			try { 
				$Context.ExecuteQuery()	
				Write-Host $header.attributes['Title'].value
				
				foreach ($node in $header.Field) {
					$NavigationNode = New-Object Microsoft.SharePoint.Client.NavigationNodeCreationInformation 
					$NavigationNode.Title = $node.attributes['Title'].value
					$NavigationNode.Url = $node.attributes['Address'].value
					$NavigationNode.PreviousNode = $topNode
					
					$Context.Load($topNode.Children.Add($NavigationNode))
					try { 
						$Context.ExecuteQuery()	
						Write-Host " --" $node.attributes['Title'].value
					} 
					catch { 
						Write-Host "Erro: " $node.attributes['Title'].value " - " $_.Exception.Message
					}
				}
			} 
			catch { 
				Write-Host "Erro: " $header.attributes['Title'].value " - " $_.Exception.Message
			}
	}
}

function DeleteOldQuickLaunch(){
	$quickLaunchNodes = $context.Web.Navigation.QuickLaunch;
	$context.Load($quickLaunchNodes);
	$context.ExecuteQuery();
	for ($ii = $quickLaunchNodes.Count - 1; $ii -ge 0; $ii--)
	{
		Write-Host "Removendo " $quickLaunchNodes[$ii].Title 
		$quickLaunchNodes[$ii].deleteObject();
		$context.ExecuteQuery();
	}
}

function CreateQuickLaunch([string]$path, [string]$url, [string]$node){
	$templateXml = [xml](get-content $path)
	$templateXml.QuickLaunch
	$xmlNodes = $templateXml.QuickLaunch.SelectNodes($node)
	
	$topNodes = $context.Web.Navigation.QuickLaunch;	
	
	foreach($header in $xmlNodes.Header){
		
		$nUrl = ($url + $header.attributes['Address'].value)
		write-host " -- " $header.attributes['Title'].value
		$OutterNavigationNode = New-Object Microsoft.SharePoint.Client.NavigationNodeCreationInformation 
		$OutterNavigationNode.Title = $header.attributes['Title'].value
		$OutterNavigationNode.Url = $nUrl
		$OutterNavigationNode.AsLastNode = $true
		$topNode = $topNodes.Add($OutterNavigationNode)
		$Context.Load($topNode)
		
		try { 
			$Context.ExecuteQuery()	
		} 
		catch { 
			Write-Host "Erro: " $header.attributes['Title'].value " - " $_.Exception.Message -Foreground 'red'
		}
	}
}

function ConfigureQuickLaunch([string]$url, [string]$email, [string]$path, [string]$node){
	while($context -eq $null){
		$context = GetClientContext $url $userEmail $Pass
		
		if($context -eq $null){
			Write-Host "Senha errada, informe a senha correta"
		}
	}
	Write-Host ("Configurando o quick launch do site " + $url) -Foreground 'yellow'
	DeleteOldQuickLaunch
	CreateQuickLaunch $path $url $node
}

$siteUrl = "https://seudominio.sharepoint.com"
$userEmail = "user@seudominio.onmicrosoft.com"

$xmlPathTopNav = "c:\caminho\menu.xml"
$xmlPathQuickLaunch = "C:\caminho\quicklaunch.xml"

$Pass = Read-Host -Prompt ("Informe a senha do usuario " + $userEmail) -AsSecureString


function configureTopMenu([string]$siteUrl, [string]$userEmail, [string]$xmlPath){
	Write-Host ("Configurando o menu superior do site " + $siteUrl)
	while($context -eq $null){
		
		$context = GetClientContext $siteUrl $userEmail $Pass
		
		if($context -eq $null){
			Write-Host "Senha errada, informe a senha correta"
		}
	}
	$templateFile = $xmlPath
	DeleteOldNavigation
	AddNavigation
	
}

configuretopmenu $siteUrl $useremail $xmlPathTopNav

ConfigureQuickLaunch $siteUrl $userEmail $xmlPathQuickLaunch 'NodeName'

Read-Host "Processo finalizado!"