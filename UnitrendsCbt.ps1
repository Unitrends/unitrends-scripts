function Reset-CBT
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        $VMName,
		[Parameter(Mandatory = $false)]
		[switch] $Force		
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
				if( ($vmView.Config.ChangeTrackingEnabled -eq $true -and $vmView.Snapshot -eq $null -and $vm.PowerState -eq "PoweredOn") -or $Force) {
					$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
					$vmConfigSpec.changeTrackingEnabled = $false
					$vmView.reconfigVM($vmConfigSpec)
														
	                New-Snapshot -Name 'unitrends_cbt_reset' -VM $vm -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
	                Get-Snapshot -Name 'unitrends_cbt_reset' -VM $vm|Remove-Snapshot -Confirm:$false -ErrorAction Stop | Out-Null
					
					$vmConfigSpec.changeTrackingEnabled = $true
					$vmView.reconfigVM($vmConfigSpec)
														
	                New-Snapshot -Name 'unitrends_cbt_reset' -VM $vm -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
	                Get-Snapshot -Name 'unitrends_cbt_reset' -VM $vm|Remove-Snapshot -Confirm:$false -ErrorAction Stop | Out-Null
					
					Write-Host "[*] $VMName : OK"
				} else {
					if($vmView.Config.ChangeTrackingEnabled -eq $false) {
						throw "CBT is disabled"			
					}elseif($vmView.Snapshot -ne $null){
						throw "VM has snapshots. use Reset-CBT -Force to ignore"			
					}elseif($vm.PowerState -ne "PoweredOn") {
						throw "VM is powered off, use Reset-CBT -Force to ignore"		
					}
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
			$error_vmlist | ft Name,PowerState,Result,Error -AutoSize
		}
	}	
} 

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
			$changeid=($newsnapview.Config.Hardware.Device | where { $_ -is [VMware.Vim.VirtualDisk] } | Select-Object -First 1).backing.changeid
			if($changeid -eq $null) {
				Write-Host "[*] $VM -> changeid is null, probably CBT is disabled"
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
			$VM | Add-Member -MemberType NoteProperty "CbtEnabled" -Value $vmView.Config.ChangeTrackingEnabled
			$vmlist += $VM 
		}
		finally {
		}	
    } 
	
	End {
		$vmlist | ft Name,PowerState,CbtEnabled -AutoSize 
	}
} 

function Disable-CBT
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        $VMName,
		[Parameter(Mandatory = $false)]
		[switch] $Force
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
				if( $vmView.Config.ChangeTrackingEnabled -eq $true -or $Force) {
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
			$error_vmlist | ft Name,PowerState,Result,Error -AutoSize
		}
	}	
} 


function Enable-CBT
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        $VMName,
		[Parameter(Mandatory = $false)]
		[switch] $Force		
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
				if( $vmView.Config.ChangeTrackingEnabled -eq $false -or $Force) {
					$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
					$vmConfigSpec.changeTrackingEnabled = $true
					$vmView.reconfigVM($vmConfigSpec)
														
	                New-Snapshot -Name 'unitrends_cbt_reset' -VM $vm -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
	                Get-Snapshot -Name 'unitrends_cbt_reset' -VM $vm|Remove-Snapshot -Confirm:$false -ErrorAction Stop | Out-Null
					Write-Host "[*] $VMName : OK"
				} else {
					throw "CBT is already enabled"
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
			$error_vmlist | ft Name,PowerState,Result,Error -AutoSize
		}
	}

} 

function CheckConnection {
	if($global:DefaultVIServers.count -le 0)
	{
		Write-Warning "You are not currently connected to any server. Please connect first using  Connect-VIServer cmdlet. `r`n" 	
		throw "You are not currently connected to any server. Please connect first using  Connect-VIServer cmdlet. `r`n" 	
	}
}

