# Configure AWS provider
provider "aws" {
}

# Request quota increase for Elastic IPs
resource "aws_servicequotas_service_quota" "eip_increase" {
  quota_code   = "L-0263D0A3"       # Fixed quota code for VPC Elastic IPs
  service_code = "ec2"              # EC2 service code
  value        = 12                 # Requested new quota value
}

data "aws_servicequotas_service_quota" "check_eip" {
  quota_code   = "L-0263D0A3"
  service_code = "ec2"
}

output "current_eip_quota" {
  value = data.aws_servicequotas_service_quota.check_eip.value
}