function Set-AzDoGlobalVariables()
{
    [CmdletBinding()]
    param
    (
        [string]$ApiVersion = "5.0"
    )
    BEGIN
    {

        # Set the API Version we want to use
        $global:AzDoApiVersion = $ApiVersion
    }
    END
    {

    }
}