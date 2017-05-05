function Find-ADObject {
    <#
        .Synopsis
        
        Function to search Active Directory using specified LDAP filter.

        .Description
        
        Function uses selected LDAP filter to search Active Directory.
        It doesn't have any external dependencies and is using ADSISearcher class.
        User can specify attributes that should be retrieved and SearchRoot.
        If you specify just one property, you will get just value of that property.
        Assumption is that you would do Select-Object -Expand/ ForEach-Object to get that property anyway.
        If you specify more properties, all of them will be retrieved. Order is preserved.

        .Example

        Find-OPADObject
        Finds all objects matching the default filter: (name=*)

        .Example

        Find-OPADObject -Filter Name=Bart*, extensionAttribute10=USER
        Finds all objects that have a Name starting with 'Bart' and with extensionAttribute10 equal to 'USER'.
        Default properties (Name, ADSPath) are returned.

        .Example
        Find-OPADObject -Filter extensionAttribute10=USER -Properties givenName, sn, Title
        Finds all objects that have extensionAttribute10 equal to 'USER' and retrieves properties: givenName, sn and Title.

        .Example
        
        Find-OPADObject -Filter extensionAttribute10=USER -Properties Name, memberof -SearchRoot 'CN=Users,DC=monad,DC=net'
        Finds all objects that have extensionAttribute10 equal to 'USER' and retrieves properties: Name and memberof.
        It will recognize memberOf as an actual collection and won't merge it into single string.
        Speficied SearchRoot is used to limit the results.

        .Example
        
        Find-OPADObject -Filter Department=HR* -Properties Name
        Finds all objects with Department like 'HR*'. Because only one property was specified, list of Names (selected property) is returned.
    #>

    [CmdletBinding()]    
    param (
        # Filter used to limit the results (use LDAP filter). 
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({
            param(
                [string]$commandName,
                [string]$parameterName,
                [string]$wordToComplete,
                [System.Management.Automation.Language.CommandAst]$commandAst,
                [System.Collections.IDictionary]$fakeBoundParameters
            )
            $types = @{
                And   = '1.2.840.113556.1.4.803', 'LDAP_MATCHING_RULE_BIT_AND'
                Or    = '1.2.840.113556.1.4.804', 'LDAP_MATCHING_RULE_BIT_OR'
                Chain = '1.2.840.113556.1.4.1941', 'LDAP_MATCHING_RULE_IN_CHAIN'
            }

            switch -Regex ($wordToComplete) {
                '^(groupType|userAccountControl):$' {
                    foreach ($key in 'And', 'Or') {
                        $line = "$_$($types.$key[0]):="
                        $attribute = $Matches[1]
                        [System.Management.Automation.CompletionResult]::new(
                            $line,
                            $line,
                            [System.Management.Automation.CompletionResultType]::ParameterValue,
                            "Matching rule $($types.$key[1]) for attribute $attribute"
                        )
                    }
                }
                '^(member|memberof):$' {
                    $line = "$_$($types.Chain[0]):="
                    $attribute = $Matches[1]
                    [System.Management.Automation.CompletionResult]::new(
                        $line,
                        $line,
                        [System.Management.Automation.CompletionResultType]::ParameterValue,
                        "Matching rule $($types.Chain[1]) for attribute $attribute"
                    )
                }
                '^(?!.*=)' {
                    $searcher = [ADSISearcher]::new(
                        [ADSI]'LDAP://CN=Schema,CN=Configuration,DC=monad,DC=net',
                        "(&(objectClass=attributeSchema)(lDAPDisplayName=$wordToComplete*))",
                        @(
                            'lDAPDisplayName'
                            'name'
                        )
                    )
                    $searcher.FindAll() | ForEach-Object {
                        $attribute = -join $_.Properties['lDAPDisplayName'][0]
                        $name = -join $_.Properties['name'][0]
                        [System.Management.Automation.CompletionResult]::new(
                            $attribute,
                            $attribute,
                            [System.Management.Automation.CompletionResultType]::ParameterValue,
                            "Attribute $attribute ($name)"
                        )                        
                    }
                }
            }
        })]
        [string[]]$Filter = '(name=*)',

        # Properties retrieved from Active Directory object (use AD attributes).
        [ArgumentCompleter({
            param(
                [string]$commandName,
                [string]$parameterName,
                [string]$wordToComplete,
                [System.Management.Automation.Language.CommandAst]$commandAst,
                [System.Collections.IDictionary]$fakeBoundParameters
            )
        
            $searcher = [ADSISearcher]::new(
                [ADSI]'LDAP://CN=Schema,CN=Configuration,DC=monad,DC=net',
                "(&(objectClass=attributeSchema)(lDAPDisplayName=$wordToComplete*))",
                @(
                    'lDAPDisplayName'
                    'name'
                )
            )
            $searcher.FindAll() | ForEach-Object {
                $attribute = -join $_.Properties['lDAPDisplayName'][0]
                $name = -join $_.Properties['name'][0]
                [System.Management.Automation.CompletionResult]::new(
                    $attribute,
                    $attribute,
                    [System.Management.Automation.CompletionResultType]::ParameterValue,
                    "Attribute $attribute ($name)"
                )                        
            }
        })]
        [string[]]$Properties = @('Name','ADSPath'),
        
        # Root of the Active Directory search (use LDAP path).
        [string[]]$SearchRoot,

        # Page size in a paged search. If zero will not use paged search.
        [Int]$PageSize = 1000,

        # Flag to include tombstones (deleted objects) in the search results.
        [Alias('Tombstone')]
        [switch]$IncludeDeleted
    )            
    
    if ($SearchRoot) {
        $rootPath = 
            if ($SearchRoot -match ',') {
                $SearchRoot[0].ToUpper()
            } else {
                ($SearchRoot -join ',').ToUpper()
            }
        if (-not $rootPath.StartsWith('LDAP://')) {
            $root = [ADSI]"LDAP://$rootPath"
        } else {
            $root = [ADSI]$rootPath
        }
    } else {            
        $root = [ADSI]''            
    }            
    
    $LDAP = '(&({0}))' -f ($Filter -join ')(')
    Write-Verbose "Using SearchRoot: $($root.Path)"
    Write-Verbose "Using LDAP Filter: $LDAP"            

    try {
        $searcher = New-Object ADSISearcher -ArgumentList @(            
                $root,            
                $LDAP,            
                $Properties
            ) -Property @{            
                PageSize = $PageSize            
        }
        
        if ($IncludeDeleted) {
            # No checks here - we will warn user once there is nothing returned...
            $searcher.Tombstone = $true
            $null = $searcher.PropertiesToLoad.Add('isDeleted')
        }

        $foundDeleted = $false
        $searcher.FindAll() | ForEach-Object {            
            if ($_.Properties['isDeleted'][0]) {
                $foundDeleted = $true
            }
            $objectProperties = [ordered]@{}
            foreach ($property in $Properties) {
                $item = @($_.Properties[$property])
                if ($item.Count -eq 1) {
                    $item = -join $item
                }
                $objectProperties.Add(            
                    $property,             
                    $item
                )
            }
            if ($objectProperties.Keys.Count -eq 1) {
                # No point in sending a collection as single object (eew)
                $objectProperties.Values | ForEach-Object { $_ }
            } else {
                New-Object PSObject -Property $objectProperties
            }
        }
        
        if ($IncludeDeleted -and -not $foundDeleted) {
            # Assumption: nothing deleted found, so perhaps search was not even possible...
            Write-Warning 'IncludeDeleted was specified but no deleted object found, possible cause:'
            Write-Output @(
                '-- too narrow SearchRoot => perhaps skip SearchRoot parameter?'
                '-- no rights to Deleted Object CN => access to object in this CN is very limited, try Domain Admin account?'
                '-- no deleted objects that match the filter => if neither applies, probably you filter is too narrow?'
            ) | Write-Warning
        }            
    } catch {
        throw "Failed to find AD objects using root: $($root.Path) and LDAP Filter $LDAP - $_"
    }
} 
