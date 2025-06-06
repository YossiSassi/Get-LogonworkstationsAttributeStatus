﻿# Get-LogonworkstationAttributeStatus, by 1nTh35h311 (comments to yossis@protonmail.com)
# v1.1 - fixed minor issue with mistakingly showing 'attribute was reset' when the LastOriginatingChangeTime and WhenCreated are equal).
# Essentially, a One-liner to get the latest Change (if ever) in Logonworkstations attribute value (Logon restrictions by user workstations) using Replication property MetaData, without any logging/auditing required.
# No special permissions required, just an authenticated domain user.

#Requires -Modules ActiveDirectory
param (
    [cmdletbinding()]
    [parameter(mandatory=$true)]
    [string[]]$UserName
)

$DC = (Get-ADDomainController -Discover).name;
$UserName -split ',' | foreach {
        $account = $_; [string]$Comment=[string]::Empty; $UserObj = Get-ADUser $account -Properties WhenCreated;
        $Result = Get-ADReplicationAttributeMetadata $UserObj -Server $DC | where attributeName -eq "userworkstations";
        if ($Result) {$Result | select @{n='Username';e={$account}},AttributeValue,@{n='ChangeTime';e={$_.LastOriginatingChangeTime}},@{n='ChangeUSN';e={$_.LastOriginatingChangeUsn}},Version,@{n='Comment';e={if ($_.AttributeValue -eq $null -and $_.LastOriginatingChangeTime -ne $UserObj.WhenCreated) {$Comment='Reset back to Default (Cleared)'};$Comment}}; Clear-Variable Comment} else {"user $account logonworkstations was never set (Empty by default)"}
    }