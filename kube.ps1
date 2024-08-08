Param (
    [Parameter(Mandatory=$true)]
    [string]$namespace,
    
    [Parameter(Mandatory=$true)]
    [string]$podName,

    [switch]$logs,
    [switch]$bash,
    [switch]$down,
    [switch]$up,


    [switch]$y
)

function Get-Pod {
    Param (
        [string]$namespace,
        [string]$podName
    )

    $pods = kubectl get pods -n $namespace -o custom-columns=":metadata.name" | Select-String $podName | ForEach-Object { $_.Line }
    return $pods
}

function Get-Deployment {
    Param (
        [string]$namespace,
        [string]$deploymentName
    )

    $deployments = kubectl get deployments -n $namespace -o custom-columns=":metadata.name" | Select-String $deploymentName | ForEach-Object { $_.Line }
    return $deployments
}

function Handle-PodOperations {
    Param (
        [string]$namespace,
        [string]$podName,
        [switch]$logs,
        [switch]$bash,
        [switch]$y
    )

    $pods = Get-Pod -namespace $namespace -podName $podName
    $podsCount = $pods.Count

    if ($podsCount -eq 0) {
        Write-Host "No pods found with the specified name in namespace '$namespace'."
        return
    }

    if ($podsCount -gt 1) {
        Write-Host "Multiple pods found. Please select one from the list:"
        
        for ($i = 0; $i -lt $podsCount; $i++) {
            Write-Host "[$($i + 1)] $($pods[$i])"
        }

        $selection = Read-Host "Enter the number of the pod you want to select, or 0 to exit"
        
        if ($selection -eq 0) {
            return
        }

        $selectedPod = $pods[$selection - 1]
    } else {
        $selectedPod = $pods
    }

    if ($y) {
        Write-Host "You have selected pod $selectedPod in namespace $namespace"
    }

    if ($logs) {
        kubectl logs $selectedPod -n $namespace
    } elseif ($bash) {
        kubectl exec -it $selectedPod -n $namespace -- /bin/bash
    }
}

function Handle-DeploymentOperations {
    Param (
        [string]$namespace,
        [string]$deploymentName,
        [switch]$down,
        [switch]$up,
        [switch]$y
    )

    $deployments = Get-Deployment -namespace $namespace -deploymentName $deploymentName
    $deploymentsCount = $deployments.Count

    if ($deploymentsCount -eq 0) {
        Write-Host "No deployments found with the specified name in namespace '$namespace'."
        return
    }

    if ($deploymentsCount -gt 1) {
        Write-Host "Multiple deployments found. Please select one from the list:"
        
        for ($i = 0; $i -lt $deploymentsCount; $i++) {
            Write-Host "[$($i + 1)] $($deployments[$i])"
        }

        $selection = Read-Host "Enter the number of the deployment you want to select, or 0 to exit"
        
        if ($selection -eq 0) {
            return
        }

        $selectedDeployment = $deployments[$selection - 1]
    } else {
        $selectedDeployment = $deployments
    }

    if ($y) {
        Write-Host "You have selected deployment $selectedDeployment in namespace $namespace"
    }

    if ($down) {
        if ($y) {
            Write-Host "Scaling down deployment $selectedDeployment in namespace $namespace"
        } else {
            $confirmation = Read-Host "Are you sure you want to scale down deployment $selectedDeployment in namespace $namespace? (y/n)"
            if ($confirmation -ne "y") {
                return
            }
        }
        kubectl scale deployment $selectedDeployment -n $namespace --replicas=0
    } elseif ($up) {
        if ($y) {
            Write-Host "Scaling up deployment $selectedDeployment in namespace $namespace"
        } else {
            $confirmation = Read-Host "Are you sure you want to scale up deployment $selectedDeployment in namespace $namespace? (y/n)"
            if ($confirmation -ne "y") {
                return
            }
        }
        kubectl scale deployment $selectedDeployment -n $namespace --replicas=1
    }
}

if ($logs -or $bash) {
    Handle-PodOperations -namespace $namespace -podName $podName -logs:$logs -bash:$bash -y:$y
} elseif ($down -or $up) {
    Handle-DeploymentOperations -namespace $namespace -deploymentName $podName -down:$down -up:$up -y:$y
} else {
    Write-Host "Please specify either -logs, -bash, -down, or -up."
}
