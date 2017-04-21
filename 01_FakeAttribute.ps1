Start-Process https://github.com/lzybkr/TabExpansionPlusPlus/commit/f4e1fef6b991b08af81bf4498d714ce03b56f780
Start-Process https://github.com/bielawb/TabExpansionPlusPlus/blob/master/Hyper-V.ArgumentCompleters.ps1
function HyperV_VMNameArgumentCompletion
{
    [ArgumentCompleter(
            Parameter = 'Name',
            # REVIEW - exclude New-VM?  Others?
            Command = { Get-CommandWithParameter -Module Hyper-V -Noun VM -ParameterName Name },
        Description = 'Complete VM names, for example: Get-VM -Name <TAB>')]
    [ArgumentCompleter(
            Parameter = 'VMName',
            Command = { Get-CommandWithParameter -Module Hyper-V -ParameterName VMName },
        Description = 'Complete VM names, for example: Set-VMMemory -VMName <TAB>')]
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

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
            New-CompletionResult $_.Name $toolTip
        }
}

$scriptBlock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

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
            New-CompletionResult $_.Name $toolTip
        }
        
}


$commandNames = Get-Command -Noun VM -ParameterName Name -Module Hyper-V |
    Where-Object Verb -NE New |
    ForEach-Object Name

Register-ArgumentCompleter -CommandName $commandNames -ParameterName Name -ScriptBlock $scriptBlock