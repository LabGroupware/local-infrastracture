variable "domain" {
  type        = string
  description = "The domain name"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster"
}

variable "host" {
  type        = string
  description = "The host of the Kubernetes cluster"
  default     = "not-set"
}

variable "client_certificate" {
  type        = string
  description = "The client certificate"
  default     = "not-set"
}

variable "client_key" {
  type        = string
  description = "The client key"
  default     = "not-set"
}

variable "cluster_ca_certificate" {
  type        = string
  description = "The cluster CA certificate"
  default     = "not-set"
}
