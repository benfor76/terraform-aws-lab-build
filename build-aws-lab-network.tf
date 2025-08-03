# Configure AWS Provider (replace region if needed)
provider "aws" {
}

# 1. Create VPC with IPv4 CIDR 10.0.0.0/24
resource "aws_vpc" "bens_vpc" {
  cidr_block = "10.0.0.0/24"
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