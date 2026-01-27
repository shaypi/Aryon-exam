param(
    [string]$ClusterName,
    [string]$Region
)

$json = aws eks get-token --cluster-name $ClusterName --region $Region
# Patch the apiVersion to satisfy the newer Terraform Kubernetes provider
$json = $json -replace "client.authentication.k8s.io/v1alpha1", "client.authentication.k8s.io/v1beta1"
Write-Output $json
