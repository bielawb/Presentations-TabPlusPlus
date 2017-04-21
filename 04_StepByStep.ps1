#region Step 1: Decide what version... Either Register-ArgumentCompleter, or attribute.
#endregion
#region Step 2: Prepare scriptblock - don't forget parameters!

function Show-VM {
    param (
        [String]$VMName = 'CentGUI',
        [string]$ComputerName = $env:COMPUTERNAME
    )
    vmconnect.exe $ComputerName $VMName
}

$vmNameCompleter = {
    param(
        [String]$commandName, 
        [String]$parameterName, 
        [String]$wordToComplete, 
        [System.Management.Automation.Language.CommandAst]$commandAst, 
        [System.Collections.IDictionary]$fakeBoundParameter
    )

    $optionalCn = @{}
    $cn = $fakeBoundParameter["ComputerName"]
    if($cn)
    {
        $optionalCn.ComputerName = $cn
    }

    Hyper-V\Get-VM -Name "$wordToComplete*" @optionalCn |
        Sort-Object |
        ForEach-Object {
            $toolTip = "State: $($_.State) Status: $($_.Status)"
            New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList @( 
                $_.Name 
                $_.Name
                'ParameterValue'
                $toolTip
            )
        }
        
}
#endregion
#region Step 3: Register using cmdlet...
Register-ArgumentCompleter -CommandName Show-VM -ParameterName VMName -ScriptBlock $vmNameCompleter

# Step 3A: Define a function with attribute...
function Show-VM { 
    param ( 
        [ArgumentCompleter(
                { 
                    & $vmNameCompleter @args 
                }
        )]
        [String]$VMName
    ) 
    
    vmconnect.exe localhost $VMName 
}
#endregion
#region Step 4: Use $wordToComplete to filter out results.
#endregion
#region Step 5: Whenever makes sense - use $fakeBoundParemeters

$vmNetworkAdapterNameCompleter = {
    param (
        [String]$commandName, 
        [String]$parameterName, 
        [String]$wordToComplete, 
        [System.Management.Automation.Language.CommandAst]$commandAst, 
        [System.Collections.IDictionary]$fakeBoundParameter
    )

    $optionalCn = @{}
    $cn = $fakeBoundParameter["ComputerName"]
    if ($cn) {
        $optionalCn.ComputerName = $cn
    }
    $vm = $fakeBoundParameter["VMName"]
    if($vm) {
        $optionalCn.VMName = $vm
    } else {
        $optionalCn.VMName = '*'
    }

    Hyper-V\Get-VMNetworkAdapter -Name "$wordToComplete*" @optionalCn |
        Sort-Object |
        ForEach-Object {
            $toolTip = "Switch: $($_.SwitchName) Status: $($_.Status)"
            New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList @( 
                $_.Name 
                $_.Name
                'ParameterValue'
                $toolTip
            )
        }
}

$VMNetAdapter = Get-Command -Module Hyper-V -Noun VMNetworkAdapter |
    Where-Object Verb -NE Add |
    ForEach-Object Name
Register-ArgumentCompleter -CommandName $VMNetAdapter -ParameterName Name -ScriptBlock $vmNetworkAdapterNameCompleter
#endregion

#region Be aware of gotchas:
#region -- quotes (solved by New-CompletionResult - may want to "borrow" solution from there)
foreach ($completion in 'foo', 'foo bar') {
    $tokens = $null
    $null = [System.Management.Automation.Language.Parser]::ParseInput(
        "echo $completion", 
        [ref]$tokens, 
        [ref]$null
    )
    if (
        $tokens.Length -ne 3 -or
        (
            $tokens[1] -is [System.Management.Automation.Language.StringExpandableToken] -and
            $tokens[1].Kind -eq [System.Management.Automation.Language.TokenKind]::Generic
        )
    ) {
        "'$completion'"
    } else {
        $completion
    }
}
#endregion
#region -- PSDefaultParameterValues are not fakeBound
$PSDefaultParameterValues.'Set-VMNetworkAdapter:VMName' = 'DC'
Set-VMNetworkAdapter -Name #...?
$vmNetworkAdapterNameCompleter = {
    param (
        [String]$commandName, 
        [String]$parameterName, 
        [String]$wordToComplete, 
        [System.Management.Automation.Language.CommandAst]$commandAst, 
        [System.Collections.IDictionary]$fakeBoundParameter
    )

    $optionalCn = @{}
    $cn = $fakeBoundParameter["ComputerName"]
    if($cn)
    {
        $optionalCn.ComputerName = $cn
    }
    $vm = $fakeBoundParameter["VMName"]
    if($vm)
    {
        $optionalCn.VMName = $vm
    }
    else
    {
        $key = '{0}:{1}' -f $commandName, 'VMName'
        if ($PSDefaultParameterValues.ContainsKey($key)) {
            $optionalCn.VMName = $PSDefaultParameterValues.$key
            Write-Verbose -Verbose -Message $key
        } else {
            $optionalCn.VMName = '*'
        }
    }

    Hyper-V\Get-VMNetworkAdapter -Name "$wordToComplete*" @optionalCn |
        Sort-Object |
        ForEach-Object {
            $toolTip = "Switch: $($_.SwitchName) Status: $($_.Status)"
            New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList @( 
                $_.Name 
                $_.Name
                'ParameterValue'
                $toolTip
            )
        }
        
}

Register-ArgumentCompleter -CommandName $VMNetAdapter -ParameterName Name -ScriptBlock $vmNetworkAdapterNameCompleter
Set-VMNetworkAdapter -Name 
#endregion
# -- ...?
#endregion