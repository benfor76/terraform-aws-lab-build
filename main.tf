# Configure AWS Provider 
provider "aws" {
}

# 1. Create VPC with IPv4 CIDR 10.0.0.0/24
resource "aws_vpc" "bens_vpc" {
  cidr_block = "10.0.0.0/24"
  enable_dns_hostnames = true
  tags = {
    Name = "Bens-Lab-Aug-25"
  }
}

# 2. Create Subnet 10.0.0.0/25
resource "aws_subnet" "bens_subnet" {
  vpc_id            = aws_vpc.bens_vpc.id
  cidr_block        = "10.0.0.0/25"
  availability_zone = "us-east-2a"  # Change if needed
  tags = {
    Name = "Bens-Lab-Aug-25"
  }
}

# 3. Create Internet Gateway
resource "aws_internet_gateway" "bens_igw" {
  vpc_id = aws_vpc.bens_vpc.id
  tags = {
    Name = "Bens-Lab-Aug-25"
  }
}

# 4. Create Route Table
resource "aws_route_table" "bens_rt" {
  vpc_id = aws_vpc.bens_vpc.id
  tags = {
    Name = "Bens-Lab-Aug-25"
  }
}

# 5. Add default route to Internet Gateway
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.bens_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.bens_igw.id
}

# 6. Associate Subnet with Route Table
resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.bens_subnet.id
  route_table_id = aws_route_table.bens_rt.id
}

# 7. Build Security Group for my Lab
resource "aws_security_group" "ben_lab_sg" {
  name        = "ben-lab-sg"
  description = "Ben Security group for lab"
  vpc_id      = aws_vpc.bens_vpc.id  # Reference to the VPC created earlier

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP/HTTPS access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL access (standard port)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Receptor access
  ingress {
    from_port   = 27199
    to_port     = 27199
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS Gateway access
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL access (alternate port)
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Redis access
  ingress {
    from_port   = 16379
    to_port     = 16379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # gRPC access
  ingress {
    from_port   = 50051
    to_port     = 50051
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (default behavior)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bens-Lab-Aug-25"
  }
}

# 1. Generate a new RSA private key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Create the AWS key pair
resource "aws_key_pair" "generated_key" {
  key_name   = "ben-lab-key-pair"  # Unique key name
  public_key = tls_private_key.key.public_key_openssh
}

# 3. Store private key in Secrets Manager
resource "aws_secretsmanager_secret" "lab_private_key" {
  name        = "ben-lab-key-pair/private"  # Secret name
  description = "Private key for key pair ${aws_key_pair.generated_key.key_name}"
}

resource "aws_secretsmanager_secret_version" "lab_private_key" {
  secret_id     = aws_secretsmanager_secret.lab_private_key.id
  secret_string = tls_private_key.lab_private_key_pem  # PEM-encoded private key
}

# 4. Retrieve the private key from Secrets Manager
data "aws_secretsmanager_secret_version" "retrieved" {
  secret_id = aws_secretsmanager_secret.lab_private_key.id
  depends_on = [aws_secretsmanager_secret_version.lab_private_key]
}

# Output results
output "key_pair_name" {
  value = aws_key_pair.generated_key.key_name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.lab_private_key.arn
}

output "retrieved_private_key" {
  value     = data.aws_secretsmanager_secret_version.retrieved.secret_string
  sensitive = true  # Marks output as sensitive in console
}

data "aws_ami" "rhelami" {
  most_recent = true
  owners      = ["309956199498"]  # Official Red Hat account
  filter {
    name   = "name"
    values = ["${var.lookup_map[var.rhel_version]}*HVM*-*Access2*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "aap25vms" {
  count                       = var.number_of_instances
  ami                         = data.aws_ami.rhelami.id
  instance_type               = "t2.xlarge"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.bens_subnet.id
  vpc_security_group_ids      = [aws_security_group.ben_lab_sg.id]
  key_name                    = "ben-lab-key-pair"

  # #Root volume configuration
  root_block_device {
    volume_size = 200    # 200 GiB
    volume_type = "gp3"
    iops        = 3000   # 3000 IOPS
    encrypted   = false  # Explicitly disable encryption
  }

  tags = {
    owner             = "bforrester"
    env               = "lab"
    operating_system  = var.rhel_version
    usage             = "aap25 lab builds"
  }
}