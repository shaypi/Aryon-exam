variable "prefix" {
  default     = "prefix"
  description = "A prefix used to define resource names, ensuring uniqueness and readability."
}

variable "project" {
  default     = "project_name"
  description = "The name of the project. This will be used to tag resources and can help with organization and filtering."
}

variable "application" {
  default     = "application"
  description = "The name of the application. Similar to the project variable, it helps in organizing resources by application."
}

variable "cluster_name" {
  type        = string
  default     = ""
  description = "The name of your EKS Cluster. This is a unique identifier within your AWS account."
}

variable "k8s_version" {
  default     = "1.20"
  type        = string
  description = "The desired Kubernetes version for the EKS cluster. It determines which Kubernetes features are available."
}

variable "kublet_extra_args" {
  default     = ""
  type        = string
  description = "Additional arguments to supply to the node kubelet process. Allows customization of the kubelet behavior."
}

variable "public_kublet_extra_args" {
  default     = ""
  type        = string
  description = "Additional arguments for the kubelet process on public nodes. It's for configurations that should only apply to nodes in a public subnet."
}

variable "vpc_id" {
  description = "The ID of the VPC where resources will be deployed. This VPC ID is usually outputted by a VPC module."
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC. This defines the IP address range of the VPC."
}

variable "vpc_subnet_cidr" {
  type        = string
  description = "The CIDR blocks for the VPC subnets. This specifies the IP range for the subnet."
}

variable "private_subnet_cidr" {
  type        = list(any)
  description = "A list of CIDR blocks for private subnets within the VPC. These subnets are used for resources that shouldn't be directly accessible from the internet."
}

variable "public_subnet_cidr" {
  type        = list(any)
  description = "A list of CIDR blocks for public subnets within the VPC. These are for resources that need direct access to the internet."
}

variable "subnet_ids" {
  type        = list(any)
  description = "A list of all the subnet IDs for both private and public subnets within the VPC."
}

variable "private_subnets" {
  description = "A list of IDs for private subnets. These subnets are used for internal resources."
}

variable "eks_cw_logging" {
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  type        = list(any)
  description = "A list of EKS cluster components for which CloudWatch logging is enabled. This helps in monitoring and troubleshooting."
}

variable "root_block_size" {
  default     = "20"
  type        = string
  description = "The size of the root EBS block device for worker nodes in GiB. This affects the available disk space."
}

variable "desired_capacity" {
  default     = 2
  type        = string
  description = "The desired number of worker nodes in the EKS cluster. The autoscaler will adjust the number of nodes based on load, within the specified min and max size bounds."
}

variable "small_instance_desired_capacity" {
  default     = 2
  type        = string
  description = "The small instance desired number of worker nodes in the EKS cluster. The autoscaler will adjust the number of nodes based on load, within the specified min and max size bounds."
}

variable "large_instance_desired_capacity" {
  default     = 2
  type        = string
  description = "The large instance desired capacity number of worker nodes in the EKS cluster. The autoscaler will adjust the number of nodes based on load, within the specified min and max size bounds."
}

variable "max_size" {
  default     = 5
  type        = string
  description = "The maximum number of worker nodes that the cluster can scale out to."
}

variable "min_size" {
  default     = 1
  type        = string
  description = "The minimum number of worker nodes that the cluster should maintain."
}

variable "endpoint_private_access" {
  description = "Indicates whether the Amazon EKS private API server endpoint is enabled. True means it is accessible only within the VPC."
}

variable "endpoint_public_access" {
  description = "Indicates whether the Amazon EKS public API server endpoint is enabled. True means it is accessible from the internet."
}

variable "max_unavailable" {
  default     = 1
  description = "The maximum number of worker nodes that can be unavailable during an update. Useful for controlling update rollout."
}

variable "aws_iam" {
  description = "Specifies the AWS IAM roles and policies required for the EKS cluster and worker nodes. Essential for defining access controls."
}

variable "account_id" {
  description = "AWS Account ID to determine capacity type"
  type        = string
}

variable "subnet_id" {
  description = "Subnets ID's for Mount Targets. These subnets are used for the spot fleet."
  type        = list(string)
}

variable "small_instance_types" {
  description = "List of allowed EC2 instance types for small nodes."
  type        = list(string)
  default     = []
}

variable "large_instance_types" {
  description = "List of allowed EC2 instance types for large nodes."
  type        = list(string)
  default     = []
}
