using namespace System.Net

Function Invoke-ExecCAExclusion {
  <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Tenant.ConditionalAccess.Read
    #>
  [CmdletBinding()]
  param($Request, $TriggerMetadata)

  $APIName = $Request.Params.CIPPEndpoint
  Write-LogMessage -headers $Request.Headers -API $APINAME -message 'Accessed this API' -Sev 'Debug'
  #If UserId is a guid, get the user's UPN
  if ($Request.body.UserId -match '^[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}$') {
    $Username = (New-GraphGetRequest -uri "https://graph.microsoft.com/v1.0/users/$($Request.body.UserId)" -tenantid $Request.body.TenantFilter).userPrincipalName
  }
  if ($Request.body.vacation -eq 'true') {
    $StartDate = $Request.body.StartDate
    $TaskBody = [pscustomobject]@{
      TenantFilter  = $Request.body.TenantFilter
      Name          = "Add CA Exclusion Vacation Mode: $Username - $($Request.body.TenantFilter)"
      Command       = @{
        value = 'Set-CIPPCAExclusion'
        label = 'Set-CIPPCAExclusion'
      }
      Parameters    = [pscustomobject]@{
        ExclusionType = 'Add'
        UserID        = $Request.body.UserID
        PolicyId      = $Request.body.PolicyId
        UserName      = $Username
      }
      ScheduledTime = $StartDate
    }
    Add-CIPPScheduledTask -Task $TaskBody -hidden $false
    #Removal of the exclusion
    $TaskBody.Parameters.ExclusionType = 'Remove'
    $TaskBody.Name = "Remove CA Exclusion Vacation Mode: $username - $($Request.body.TenantFilter)"
    $TaskBody.ScheduledTime = $Request.body.EndDate
    Add-CIPPScheduledTask -Task $TaskBody -hidden $false
    $body = @{ Results = "Successfully added vacation mode schedule for $Username." }
  }
  else {
    Set-CIPPCAExclusion -TenantFilter $Request.body.TenantFilter -ExclusionType $Request.body.ExclusionType -UserID $Request.body.UserID -PolicyId $Request.body.PolicyId -Headers $Request.Headers -UserName $Username
  }


  Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
      StatusCode = [HttpStatusCode]::OK
      Body       = $Body
    })

}
