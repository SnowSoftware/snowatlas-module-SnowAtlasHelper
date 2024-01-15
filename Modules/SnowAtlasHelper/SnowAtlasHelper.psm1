#region API Communication
function Get-SnowAtlasRequestHeaders {
    param($clientId, $clientSecret, $tenantUrl, [switch]$forceNew)

    $headers = $null
    if (-not $global:SnowAtlasTokenHeadersRetreiveTime -or $forceNew) {
        [datetime]$tokenLastRetrievedDate = "1977-07-14"
    }
    else {
        [datetime]$tokenLastRetrievedDate = $global:SnowAtlasTokenHeadersRetreiveTime
    }
    if (-not $global:SnowAtlasTokenHeaders -or $tokenLastRetrievedDate -lt (Get-Date).AddHours(-1)) {
        $ReqTokenBody = @{grant_type = "client_credentials"
            client_id                = $clientId
            client_secret            = $clientSecret
        } 
        $contentType = 'application/x-www-form-urlencoded'

        $TokenResponse = Invoke-RestMethod -Uri "$tenantUrl/idp/api/connect/token" -Method POST -Body $ReqTokenBody -ContentType $contentType
    
        $headers = @{
            "Authorization" = "Bearer $($TokenResponse.access_token)"
            'Content-Type'  = "application/json"
        }
        $global:SnowAtlasTokenHeaders = $headers
        $global:SnowAtlasTokenHeadersRetreiveTime = (Get-Date).ToString()
    }
    else {
        $headers = $global:SnowAtlasTokenHeaders
    }

    

    return $headers

}

function Get-SnowAtlasAPIResult {
    param(
        $requestHeaders,
        $ApiPath,
        $tenantUri,
        $TimeoutSeconds = 20
    )

    $uri = $tenantUri + $ApiPath
    $res = Invoke-RestMethod -Uri $uri -Method Get -Headers $requestHeaders
    if ($null -eq $res.pagination) {
        return $res
    }

    $items = $res.items

    $next = $res._links | Where-Object { $_.rel -eq 'next' } | Select-Object -ExpandProperty href

    
    $TimeoutTimer = [Diagnostics.Stopwatch]::StartNew()

    while($next -and ($TimeoutTimer.elapsed.totalseconds -lt $TimeoutSeconds)) {
        $uri = $tenantUri + $next
        $res = Invoke-RestMethod -Uri $uri -Method Get -Headers $requestHeaders
        $items += $res.items
        $next = $res._links | Where-Object { $_.rel -eq 'next' } | Select-Object -ExpandProperty href
    }

    if ($next) {
        Write-Warning "Could not retrieve all pages within timeout ($TimeoutSeconds seconds). Increase timeout to retrieve all pages."
    }

    $TimeoutTimer.stop() 

    return $items

}
#endregion

#region SAM Core functions
function Get-SnowAtlasApplicationUsageData {
    param(
        $requestHeaders,
        $tenantUri,
        $applicationId
    )

    $res = Get-SnowAtlasAPIResult -tenantUri $tenantUri -ApiPath "/api/sam/estate/v1/computers-applications?filter=applicationId -eq '$applicationId'" -requestHeaders $requestHeaders
    return $res
    
}

function Get-SnowAtlasApplicationInfo {
    param(
        $requestHeaders,
        $tenantUri,
        $applicationId
    )

    $res = Get-SnowAtlasAPIResult -tenantUri $tenantUri -ApiPath "/api/sam/software-registry/v1/applications/$applicationId" -requestHeaders $requestHeaders
    return $res
    
}

function Get-SnowAtlasComputers {
    param(
        $requestHeaders,
        $tenantUri        
    )

    $res = Get-SnowAtlasAPIResult -tenantUri $tenantUri -ApiPath "/api/sam/estate/v1/computers?page_size=800" -requestHeaders $requestHeaders
    return $res
    
}

#Replaced with Get-SnowAtlasComputerInfo
function Get-SnowAtlasComputerDetails {
    # param(
    #     $requestHeaders,
    #     $tenantUri,
    #     $computerId     
    # )

    # $res = Get-SnowAtlasAPIResult -endPointUri "$tenantUri/api/sam/estate/v1/computers/$computerId" -requestHeaders $requestHeaders

    Write-Warning "Replaced with Get-SnowAtlasComputerInfo"

    # return $res
    
}

function Get-SnowAtlasComputerInfo {
    param(
        $requestHeaders,
        $tenantUri,
        $computerId
    )

    try {
        $res = Get-SnowAtlasAPIResult -tenantUri $tenantUri -ApiPath "/api/sam/estate/v1/computers/$computerId" -requestHeaders $requestHeaders
        return $res
    }
    catch {
        write-error "Error trying to get Computer info for computer $computerId. Error message: $_"
    }
    
}

function Get-SnowAtlasComputerRegistry {
    param(
        $requestHeaders,
        $tenantUri,
        $computerId
    )

    try {
        $res = Get-SnowAtlasAPIResult -tenantUri $tenantUri -ApiPath "/api/sam/estate/v1/computers/$computerId/registry" -requestHeaders $requestHeaders
        return $res
    }
    catch {
        write-error "Error trying to get Computer info for computer $computerId. Error message: $_"
    }
    
}

function Get-SnowAtlasUserInfo {
    param(
        $requestHeaders,
        $tenantUri,
        $userId
    )

    try {
        $res = Get-SnowAtlasAPIResult -tenantUri $tenantUri -ApiPath "/api/sam/estate/v1/user-accounts/$userId" -requestHeaders $requestHeaders
        return $res
    }
    catch {
        write-error "Error trying to get User info for user $userId. Error message: $_"
    }
    
}
#endregion

#region SaaS Functions
#/saas/insight-generator/v1/insights/{subscriptionId}
function Get-SnowAtlasSaaSinsights {
    param(
        $requestHeaders,
        $tenantUri,
        $subscriptionId
    )

    try {
        $res = Get-SnowAtlasAPIResult -tenantUri $tenantUri -ApiPath "/api/sam/estate/v1/user-accounts/$subscriptionId" -requestHeaders $requestHeaders
        return $res
    }
    catch {
        write-error "Error trying to get User info for user $subscriptionId. Error message: $_"
    }
    
}
#endregion