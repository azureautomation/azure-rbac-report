<#
.Synopsis
   The script will enumerate and report Azure subscription RBAC definitions and assigned users.

.DESCRIPTION
   The script will enumerate and report Azure subscription RBAC definitions and assigned users.The report will be generated in the script execution directory. In order to run the script, the session it is execute from, must be logged in to Azure using login-azurermaccount or add-azurermaccount.

.EXAMPLE
   Example of how to use this script with keep parameters. This will save report data for later comparison
   .\RBACReportv2.ps1 -keep

.EXAMPLE
   Example of how to use this script and compare data from previous reports
   .\RBACReportv2.ps1 -compare -PreviousReport .\RBAC_Report_[Snapshot Date].csv

.PARAMETER Compare
   Set the script on for compare with previous report data

.PARAMETER PreviousReport
   Set the path for the csv file with previous report data to use for comparison

.PARAMETER Keep
   Set report data to be saved for later use 

.PARAMETER ExcludeEmptyRoles
   Switch to override default behaviour for removing empty roles

#>

#############################################################################
#                                     			 		                    #
#   This Sample Code is provided for the purpose of illustration only       #
#   and is not intended to be used in a production environment.  THIS       #
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #
#   right to use and modify the Sample Code and to reproduce and distribute #
#   the object code form of the Sample Code, provided that You agree:       #
#   (i) to not use Our name, logo, or trademarks to market Your software    #
#   product in which the Sample Code is embedded; (ii) to include a valid   #
#   copyright notice on Your software product in which the Sample Code is   #
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #
#   Our suppliers from and against any claims or lawsuits, including        #
#   attorneys' fees, that arise or result from the use or distribution      #
#   of the Sample Code.                                                     #
#                                     			 		                    #
#   Version 2.0                              			 	                #
#   Last Update Date: 14 Nov  2018                           	            #
#                                     			 		                    #
#############################################################################

#Requires -version 4
#Requires -module AzureRM.Resources

Param([Parameter(ParameterSetName='CollectSet')][Bool]$ExcludeEmptyRoles=$true,[Parameter(ParameterSetName='CollectSet')][Switch]$Keep,[Parameter(ParameterSetName='CompareSet')][Switch]$Compare,[Parameter(ParameterSetName='CompareSet')][String]$PreviousReport)

$fileName = "RBAC_Report_$(get-date -Format ddMMyyyy).html"

if ($Compare)
{
    if (!(Test-Path $PreviousReport))
    {
    Write-Error "$PreviousReport file cannot be found!, please correct file path."
    Exit
    }
}

Login-AzureRmAccount -ErrorVariable loginerror
If ($loginerror -ne $null)
{
Throw {"Error: An error occured during the login process, please correct the error and try again."}
}

Function Select-Subs
{
    $ErrorActionPreference = 'SilentlyContinue'
    $Menu = 0
    $Subs = @(Get-AzureRmSubscription | select Name,ID,TenantId)

    Write-Host "Please select the subscription you want to use" -ForegroundColor Green;
    $Subs | %{Write-Host "[$($Menu)]" -ForegroundColor Cyan -NoNewline ;Write-host ". $($_.Name)";$Menu++;}
    $selection = Read-Host "Please select the Subscription Number - Valid numbers are 0 - $($Subs.count -1)"
    If ($Subs.item($selection) -ne $null)
    { Return @{name = $subs[$selection].Name;ID = $subs[$selection].ID} }
}

$SubscriptionSelection = Select-Subs
Select-AzureRmSubscription -SubscriptionName $SubscriptionSelection.Name -ErrorAction Stop

$Report = @{}

Get-AzureRmRoleDefinition | %{$Report."$($_.Id)" = @{Name = $_.Name;
                                Id = $_.Id
                                Description = $_.Description
                                Actions = $_.Actions 
                                NotActions = $_.NotActions 
                                User = @()}} -ErrorAction Stop

Get-AzureRmRoleAssignment |%{$Report."$($_.RoleDefinitionId)".User += [PSCustomObject]@{DisplayName = $_.DisplayName; SignInName = $_.SignInName ; UserScope = $_.Scope}} -ErrorAction Stop


if ($Keep)
{
    Foreach ($Role in $Report.Keys)
    {
    $obj = [PsCustomObject]@{Id = $Role
                             Name = "$($Report.$role.Name)"
                             Description = "$($Report.$role.Description)"
                             Actions = "$($Report.$role.Actions -join ',')"
                             NotActions = "$($Report.$role.NotActions -join ',')"
                             User = ($Report.$Role.User | select @{N='Users';e={"$($_.DisplayName )<f>$($_.SigninName)<f>$($_.UserScope)"}}).Users -join '<>'
                             }
    $obj | Export-Csv $fileName.Replace('.html','.csv') -Append
    }
}


Function Compare-Actions
{Param($Id)
$AllActions = @()
    If ($Report.$id.Name -notlike '[*] - *')
    {
        Foreach ($Action in @($Report.$ID.Actions))
        {
       
            If (@($Rpt.$id.Actions) -contains $Action)
            {
            $AllActions += $Action
       
            }Else
            {
            $AllActions += "$Action <font color='red'>[Added]</font>"
            }
        }

       Foreach ($Action in @($rpt.$ID.Actions | ?{$_ -ne ''}))
        {
            If (@($Report.$id.Actions) -notcontains $Action)
            {
            $AllActions += "$Action <font color='red'>[Removed]</font>"
            }
        }

    }
   
    Return $AllActions

}

Function Compare-notActions
{Param($Id)
$AllActions = @()
    If ($Report.$id.Name -notlike '[*] - *')
    {
        Foreach ($Action in @($Report.$ID.notActions))
        {
            If (@($Rpt.$id.notActions) -contains $Action)
            {
            $AllActions += $Action
            
            }Else
            {
                
                $AllActions += "$Action <font color='red'>[Added]</font>"
                
            }
        }

       Foreach ($Action in @($rpt.$ID.notActions | ?{$_ -ne ''}))
        {
            If (@($Report.$id.notActions) -notcontains $Action)
            {
              
               
                $AllActions += "$Action <font color='red'>[Removed]</font>"
              
            }
        }

    }

    Return $AllActions

}

Function Compare-User
{Param($Id)

    If ($Report.$id.Name -notlike '[*] - *')
    {
    $AllUsers = @()
        Foreach ($usr in @($Report.$id.User))
        {
                
            if (@(($rpt.$id.User | ?{($_.DisplayName -eq $usr.DisplayName) -and ($_.UserScope -eq $usr.UserScope) })).count -gt 0)
            {
            $AllUsers += $usr
            }
            else
            {
                      #          if (($usr.DisplayName -ne $null -or $usr.DisplayName -ne ''))
                       #             {
                                       $AllUsers += [PSCustomObject]@{DisplayName = "$($usr.DisplayName) <font color='red'>[Added]</font>" 
                                                           UserScope = $($usr.UserScope)
                                                          }
                        #            }
            }
        }

        Foreach ($usr in @($rpt.$id.User |?{$_.DisplayName -ne ''}))
        {
            if (@(($Report.$id.User | ?{($_.DisplayName -eq $usr.DisplayName) -and ($_.UserScope -eq $usr.UserScope) })).count -lt 1)
            {

                    $AllUsers += [PSCustomObject]@{DisplayName = "$($usr.DisplayName) <font color='red'>[Removed]</font>" 
                                                   UserScope = $($usr.UserScope)
                     }                             

            }
        }

    return $AllUsers
    }
}

IF ($Compare)
{
#Import Previous report
$rpt = @{}
            import-csv $PreviousReport | %{$Rpt."$($_.Id)" = @{Name = $_.Name;
                                Id = $_.Id
                                Description = $_.Description
                                Actions = ($_.Actions -split ',')
                                NotActions = ($_.NotActions  -split ',')
                                User = @( $_.user -split '<>' | %{[PSCustomObject]@{DisplayName = ($_ -split '<f>')[0]
                                                                                    SigninName =  ($_ -split '<f>')[1]
                                                                                    UserScope =   ($_ -split '<f>')[2]} })}}


    Foreach ($RoleID in $Report.Keys)
    {
           #Check if role is new or existing
           If (!($rpt.ContainsKey($RoleID)))
           {
           $RS1 = $Report.$RoleID.Name
           $Report.$RoleID.Name = "$RS1 <font color='red'>[New Role]</font>"
           }
    }

    #Check if any roles was removed 
    Foreach ($RptID in $rpt.Keys)
    {
           If (!($Report.ContainsKey($RptID)))
           {
           $Report.$RptID = $Rpt.$RptID
           $RS2 = $Report.$RptID.Name
           $Report.$RptID.Name = "$RS2 <font color='red'>[Role removed]</font>"
           }
    }

        Foreach ($RoleID in $Report.Keys)
    {
    $Report.$RoleID.Actions = Compare-Actions -Id $RoleID
    $Report.$RoleID.notActions = Compare-notActions -id $RoleID
    $Report.$RoleID.User = Compare-User -id $RoleID
   }

}


IF ($ExcludeEmptyRoles)
{
$list = [System.Collections.ArrayList]($Report.GetEnumerator() |?{$_.value.name -notlike '[*]*' -and ($_.value.user.displayname -eq $null -or $_.value.user.displayname -eq '')} ).Key
    foreach ($Item in $list)
    {

        $Report.Remove($Item)

    }
}


$Export = @()
$Export += @"
<html><head><Title>RBAC Report - $(Get-Date) </Title>
<Style>
table {
    width: 1024px;
}
th {
	font: bold 11px "Trebuchet MS", Verdana, Arial, Helvetica,
	sans-serif;
	color: #FFFFFF;
	border-right: 1px solid #C1DAD7;
	border-bottom: 1px solid #C1DAD7;
	border-top: 1px solid #C1DAD7;
	letter-spacing: 2px;
	text-transform: uppercase;
	text-align: left;
	padding: 6px 6px 6px 12px;
	background: #5F9EA0;
}
td {
	font: 11px "Trebuchet MS", Verdana, Arial, Helvetica,
	sans-serif;
	border-right: 1px solid #C1DAD7;
	border-bottom: 1px solid #C1DAD7;
	background: #fff;
	padding: 6px 6px 6px 12px;
	color: #6D929B;
}

</Style>
</head><body>
"@

        

Foreach ($Role in $Report.Keys)
{

$Export += @"
<Table>
<tr><th colspan='2'>$($Report.$role.Name) </th></tr>
<tr><td Colspan='2'>$($Report.$role.Description)</td></tr>
<tr><td>Actions</td><td>NotActions</td></tr>
<tr><td>$($Report.$role.Actions -join  '<br>')</td><td>$($Report.$role.NotActions -join  '<br>')</td></tr>
<tr><td>UserName</td><td>UserScope</td></tr>
$($Report.$role.User | %{"<tr><td>$($_.DisplayName)</td><td>$($_.UserScope -join '<br>')</td></tr>" })
</Table>
<br>
"@
}
$Export += '</body></html>'

$Export | Out-File $fileName -Force
Write-Host "Report Done! - Filename: $fileName" -ForegroundColor Green


