class NoMethod : System.Management.Automation.IArgumentCompleter {}    

class MethodWithoutParameters : System.Management.Automation.IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[System.Management.Automation.CompletionResult]] CompleteArgument () {
        return [System.Management.Automation.CompletionResult[]]@()
    }
}

Start-Process 'https://msdn.microsoft.com/en-us/library/system.management.automation.iargumentcompleter.completeargument(v=vs.85).aspx'

class NoResults : System.Management.Automation.IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[System.Management.Automation.CompletionResult]] CompleteArgument (
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [System.Management.Automation.Language.CommandAst] $commandAst,
        [System.Collections.IDictionary] $fakeBoundParameters
           
    ) {
        return [System.Management.Automation.CompletionResult[]]@()
    }
}

function Test-NoResult {
    param (
        [ArgumentCompleter([NoResults])]
        [String]$Parameter
    )

    $Parameter
}

class PrefixIt : System.Management.Automation.IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[System.Management.Automation.CompletionResult]] CompleteArgument (
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [System.Management.Automation.Language.CommandAst] $commandAst,
        [System.Collections.IDictionary] $fakeBoundParameters
           
    ) {
        return [System.Management.Automation.CompletionResult[]]@(
            foreach ($prefix in 'Pre:', 'Post:', 'Foo:', 'Bar:') {
                [System.Management.Automation.CompletionResult]::new(
                    "${prefix}${wordToComplete}",
                    "With $prefix",
                    [System.Management.Automation.CompletionResultType]::ParameterValue,
                    "Addin $prefix to $commandName parameter value $wordToComplete"
                )
            }
        )
    }
}
 
function Test-PrefixIt {
    param (
        [ArgumentCompleter([PrefixIt])]
        [String]$Parameter
    )

    $Parameter
}
                       