# Log In
Connect-AzAccount

# View current subscription
Get-AzContext

# Set subscription 
Get-AzSubscription
Set-AzContext -SubscriptionId "926771bb-5cdd-42a8-908b-04ef2a6d0343"

$subscriptionID="926771bb-5cdd-42a8-908b-04ef2a6d0343"
$hostpoolRG="rg-avd-004"

$AVDscalingroleUrl= "https://raw.githubusercontent.com/MarksMultiverse/AVD-Scaling/main/AVDscalingrole.json"
$AVDscalingrolePath= "AVDscalingrole.json"

# Download the file
Invoke-WebRequest -Uri $AVDscalingroleUrl -OutFile $AVDscalingrolePath -UseBasicParsing

# Update the file
((Get-Content -path $AVDscalingrolePath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $AVDscalingrolePath
((Get-Content -path $AVDscalingrolePath -Raw) -replace '<rgName>', $hostpoolRG) | Set-Content -Path $AVDscalingrolePath

# Create custom roles
New-AzRoleDefinition -InputFile  .\AVDscalingrole.json

# Get variable for applicatio ID
$objId = (Get-AzADServicePrincipal -AppId "9cdead84-a844-4324-93f2-b2e6bb768d07").Id

# Grant role definition to image builder service principal
New-AzRoleAssignment -ObjectId $objId -RoleDefinitionName "Desktop Virtualization Autoscale" -Scope "/subscriptions/$subscriptionID/resourceGroups/$hostpoolRG"

# Create autoscale scedule
$scalingparameters = @{
    ScalingPlanName   = "AVDTestScalingPlan"
    ResourceGroupName = $hostpoolRG
    location         = "WestEurope"
    HostpoolType      = "Pooled"
    Description       = "Scaling plan for AVD"
    FriendlyName      = "Scaling plan for AVD"
    AssignToHostPool = @{$hostPoolName = $hostpoolRG}
    ScheduleName     = "ScheduleWeekdays"
    ScheduleDays     = @("Monday", "Tuesday", "WednesDay", "Thursday", "Friday", "Saturday", "Sunday")
    rampUpStartTime   = "07:00"
    rampUpLoadBalancingAlgorithm = "DepthFirst"
    rampUpMinimumHostsPct = 20
    rampUpCapacityThresholdPct = 70
    peakStartTime = "08:00"
    peakLoadBalancingAlgorithm = "BreadthFirst"
    rampDownStartTime = "18:00"
    rampDownLoadBalancingAlgorithm = "DepthFirst"
    rampDownMinimumHostsPct = 20
    rampDownCapacityThresholdPct = 50
    rampDownForceLogoffUsers = $true
    rampDownWaitTimeMinutes = 30
    rampDownNotificationMessage = "Wegens inactiviteit zal uw sessie worden afgesloten"
    offPeakStartTime = "20:00"
    offPeakLoadBalancingAlgorithm = "DepthFirst"
}
New-AvdScalingPlan @scalingparameters

