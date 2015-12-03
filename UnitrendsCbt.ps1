function Get-ChangeId
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        $VM
    )

	Begin{
		CheckConnection
	}
	
    Process {  
		try {

			$vmView = $vm | get-view
			$newSnap = New-Snapshot -VM $vm -Name "get_changeid" -ErrorAction Stop -WarningAction SilentlyContinue
			$newSnapview = $newSnap | Get-View 
			#$changes=$vmview.QueryChangedDiskAreas($newSnapview.MoRef, 2000, 0, "*")
			$changeid=($newsnapview.Config.Hardware.Device | where { $_.Key -eq 2000 }).backing.changeid
			if($changeid -eq $null) {
				Write-Host "[*] $VM -> CBT is disabled"
			} else {
				Write-Host "[*] $VM -> $changeid"
			}
			Get-Snapshot -Name 'get_changeid' -VM $vm|Remove-Snapshot -Confirm:$false -ErrorAction Stop | Out-Null
		}
		catch [Exception]{
				$error_vmlist += $CurrentVM
				Write-Warning  "[*] $VM : Failed to get ChangeID: $_"
		}
	}
}

function Get-CBT
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        $VM
    )

	Begin{
		CheckConnection
		[array] $vmlist = $null
	}
	
    Process {  
		try {		
			$vmView = $VM | get-view
			$vmView | Add-Member -MemberType NoteProperty "CbtEnabled" -Value $vmView.Config.ChangeTrackingEnabled
			$vmlist += $vmView 
		}
		finally {
		}	
    } 
	
	End {
		$vmlist | ft Name,PowerState,CbtEnabled
	}
} 

function Disable-CBT
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        $VMName
    )

	Begin{
		CheckConnection
		[array]$error_vmlist = $null
	}
	
    Process {      
			try{		
	        	$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

        		$vm = Get-vm $VMName -ErrorAction Stop
				$vmView = $vm | get-view
				if( $vmView.Config.ChangeTrackingEnabled -eq $true) {
					$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
					$vmConfigSpec.changeTrackingEnabled = $false
					$vmView.reconfigVM($vmConfigSpec)
														
	                New-Snapshot -Name 'unitrends_cbt_reset' -VM $vm -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
	                Get-Snapshot -Name 'unitrends_cbt_reset' -VM $vm|Remove-Snapshot -Confirm:$false -ErrorAction Stop | Out-Null
					Write-Host "[*] $VMName : OK"
				}
			}
			catch [Exception]{
				$vm | Add-Member -MemberType NoteProperty "Result" -Value "Failed"
				$vm | Add-Member -MemberType NoteProperty "Error" -Value "$_"
				$error_vmlist += $vm
				Write-Warning  "[*] $VMName : FAILED ( $_ )"
			}

    } # End of process
	
	End {
		Write-Host ""
		if($error_vmlist -ne $null) {
			Write-Warning "CBT Reset failed on these Virtual Machines:"	
			$error_vmlist | ft Name,PowerState,Result,Error
		}
	}
	
} 


function Enable-CBT
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        $VMName
    )

	Begin{
		CheckConnection
		[array]$error_vmlist = $null
	}
	
     Process {      
			try{		
	        	$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

        		$vm = Get-vm $VMName -ErrorAction Stop
				$vmView = $vm | get-view
				if( $vmView.Config.ChangeTrackingEnabled -eq $false) {
					$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
					$vmConfigSpec.changeTrackingEnabled = $true
					$vmView.reconfigVM($vmConfigSpec)
														
	                New-Snapshot -Name 'unitrends_cbt_reset' -VM $vm -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
	                Get-Snapshot -Name 'unitrends_cbt_reset' -VM $vm|Remove-Snapshot -Confirm:$false -ErrorAction Stop | Out-Null
					Write-Host "[*] $VMName : OK"
				}
			}
			catch [Exception]{
				$vm | Add-Member -MemberType NoteProperty "Result" -Value "Failed"
				$vm | Add-Member -MemberType NoteProperty "Error" -Value "$_"
				$error_vmlist += $vm
				Write-Warning  "[*] $VMName : FAILED ( $_ )"
			}

    } # End of process
	
	End {
		Write-Host ""
		if($error_vmlist -ne $null) {
			Write-Warning "CBT Reset failed on these Virtual Machines:"	
			$error_vmlist | ft Name,PowerState,Result,Error
		}
	}

} 

function CheckConnection {
	if($global:DefaultVIServers.count -le 0)
	{
		throw "You are not currently connected to any server. Please connect first using  Connect-VIServer cmdlet. `r`n" 		
	}
}

