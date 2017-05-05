# With TabExpansionPlusPlus installed - using New-CompletionResult
$completerV4 = {
    1..10 | ForEach-Object {
        $splat = @{
            CompletionText = "$_"
            ListItemText = "Pick me - $_"
            CompletionResultType = 'ParameterValue'
            ToolTip = "please select $_ - it's the best number ever!"
        }
        New-CompletionResult @splat
    }
}

# V5 - so we go with new syntax: [ClassName]::new() - function New-CompletionResult gone missing...
$completerV5 = {                                                                               
    1..10 | ForEach-Object {                                                                                                   
        [System.Management.Automation.CompletionResult]::new(                                                         
            $_,                                                                                                           
            "Pick me - $_",                                                                                               
            [System.Management.Automation.CompletionResultType]::ParameterValue,                                          
            "please select $_ - it's the best number ever!"                                                               
        )                                                                                                             
    }                                                                                                             
}                                                                                                             

# If you don't want don't need to worry about quotes... New-CompletionResult is just New-Object wrapper...
$completer = {
    1..10 | ForEach-Object {                                                                                                   
        New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList @(                                                         
            $_,                                                                                                           
            "Pick me - $_",                                                                                               
            [System.Management.Automation.CompletionResultType]::ParameterValue,                                          
            "please select $_ - it's the best number ever!"                                                               
        )                                                                                                             
    }                                                                                                             
    
}

function Test-Completer { 
    param (
        [int]$First,
        [int]$Second,
        [int]$Third
    ) 
    
    "$First - $Second - $Third"
}                                                

Register-ArgumentCompleter -CommandName Test-Completer -ParameterName First -ScriptBlock $completerV5
Register-ArgumentCompleter -CommandName Test-Completer -ParameterName Second -ScriptBlock $completerV4
Register-ArgumentCompleter -CommandName Test-Completer -ParameterName Third -ScriptBlock $completer
"The version is $($PSVersionTable.PSVersion)"


Enter-PSSession -ComputerName dc.monad.net -Credential $MonadCredentials
Exit-PSSession
