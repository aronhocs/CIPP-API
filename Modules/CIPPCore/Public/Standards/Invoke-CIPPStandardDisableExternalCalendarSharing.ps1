function Invoke-CIPPStandardDisableExternalCalendarSharing {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) DisableExternalCalendarSharing
    .SYNOPSIS
        (Label) Disable external calendar sharing
    .DESCRIPTION
        (Helptext) Disables the ability for users to share their calendar with external users. Only for the default policy, so exclusions can be made if needed.
        (DocsDescription) Disables external calendar sharing for the entire tenant. This is not a widely used feature, and it's therefore unlikely that this will impact users. Only for the default policy, so exclusions can be made if needed by making a new policy and assigning it to users.
    .NOTES
        CAT
            Exchange Standards
        TAG
            "CIS"
            "exo_individualsharing"
        ADDEDCOMPONENT
        IMPACT
            Low Impact
        ADDEDDATE
            2024-01-08
        POWERSHELLEQUIVALENT
            Get-SharingPolicy \| Set-SharingPolicy -Enabled \$False
        RECOMMENDEDBY
            "CIS"
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/list-standards
    #>

    param($Tenant, $Settings)
    $TestResult = Test-CIPPStandardLicense -StandardName 'DisableExternalCalendarSharing' -TenantFilter $Tenant -RequiredCapabilities @('EXCHANGE_S_STANDARD', 'EXCHANGE_S_ENTERPRISE', 'EXCHANGE_LITE') #No Foundation because that does not allow powershell access

    if ($TestResult -eq $false) {
        Write-Host "We're exiting as the correct license is not present for this standard."
        return $true
    } #we're done.
    ##$Rerun -Type Standard -Tenant $Tenant -Settings $Settings 'DisableExternalCalendarSharing'

    try {
        $CurrentInfo = New-ExoRequest -tenantid $Tenant -cmdlet 'Get-SharingPolicy' |
        Where-Object { $_.Default -eq $true }
    }
    catch {
        $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
        Write-LogMessage -API 'Standards' -Tenant $Tenant -Message "Could not get the DisableExternalCalendarSharing state for $Tenant. Error: $ErrorMessage" -Sev Error
        return
    }

    if ($Settings.remediate -eq $true) {
        if ($CurrentInfo.Enabled) {
            $CurrentInfo | ForEach-Object {
                try {
                    New-ExoRequest -tenantid $Tenant -cmdlet 'Set-SharingPolicy' -cmdParams @{ Identity = $_.Id ; Enabled = $false } -UseSystemMailbox $true
                    Write-LogMessage -API 'Standards' -tenant $tenant -message "Successfully disabled external calendar sharing for the policy $($_.Name)" -sev Info
                } catch {
                    $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
                    Write-LogMessage -API 'Standards' -tenant $tenant -message "Failed to disable external calendar sharing for the policy $($_.Name). Error: $ErrorMessage" -sev Error
                }
            }
        } else {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'External calendar sharing is already disabled' -sev Info

        }

    }

    if ($Settings.alert -eq $true) {
        if ($CurrentInfo.Enabled) {
            Write-StandardsAlert -message 'External calendar sharing is enabled' -object ($CurrentInfo | Select-Object enabled) -tenant $tenant -standardName 'DisableExternalCalendarSharing' -standardId $Settings.standardId
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'External calendar sharing is enabled' -sev Info
        } else {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'External calendar sharing is not enabled' -sev Info
        }
    }

    if ($Settings.report -eq $true) {
        $CurrentInfo.Enabled = -not $CurrentInfo.Enabled
        Set-CIPPStandardsCompareField -FieldName 'standards.DisableExternalCalendarSharing' -FieldValue $CurrentInfo.Enabled -TenantFilter $Tenant
        Add-CIPPBPAField -FieldName 'ExternalCalendarSharingDisabled' -FieldValue $CurrentInfo.Enabled -StoreAs bool -Tenant $tenant
    }
}
