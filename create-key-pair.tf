# Generate a new RSA private key
resource "tls_private_key" "ben_lab_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair using the public key
resource "aws_key_pair" "ben_lab_key" {
  key_name   = "ben-lab-key"
  public_key = tls_private_key.ben_lab_key.public_key_openssh
}

# Save private key to local file
resource "local_file" "private_key" {
  content  = tls_private_key.ben_lab_key.private_key_pem
  filename = "ben-lab-key.pem"
  file_permission = "0400"  # Restrict permissions
}

# Output the private key (use with caution!)
output "private_key" {
  value     = tls_private_key.ben_lab_key.private_key_pem
  sensitive = true  # Marks output as sensitive
}