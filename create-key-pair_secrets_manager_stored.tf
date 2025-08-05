# 1. Generate a new RSA private key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Create the AWS key pair
resource "aws_key_pair" "generated_key" {
  key_name   = "my-key-pair"  # Unique key name
  public_key = tls_private_key.key.public_key_openssh
}

# 3. Store private key in Secrets Manager
resource "aws_secretsmanager_secret" "private_key" {
  name        = "my-key-pair/private"  # Secret name
  description = "Private key for key pair ${aws_key_pair.generated_key.key_name}"
}

resource "aws_secretsmanager_secret_version" "private_key" {
  secret_id     = aws_secretsmanager_secret.private_key.id
  secret_string = tls_private_key.key.private_key_pem  # PEM-encoded private key
}

# 4. Retrieve the private key from Secrets Manager
data "aws_secretsmanager_secret_version" "retrieved" {
  secret_id = aws_secretsmanager_secret.private_key.id
  depends_on = [aws_secretsmanager_secret_version.private_key]
}

# Output results
output "key_pair_name" {
  value = aws_key_pair.generated_key.key_name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.private_key.arn
}

output "retrieved_private_key" {
  value     = data.aws_secretsmanager_secret_version.retrieved.secret_string
  sensitive = true  # Marks output as sensitive in console
}