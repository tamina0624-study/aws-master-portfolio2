# terraform/vpc.tf

# 1. VPCの定義
resource "aws_vpc" "main" {
  cidr_block           = "10.11.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "11-devsecops-vpc"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "11-devsecops-igw"
  }
}

# 3. Public Subnets (1a, 1c)
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.11.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "11-public-1a"
    "kubernetes.io/role/elb" = "1" # ALB Controller用
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.11.2.0/24"
  availability_zone       = "us-east-2c"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "11-public-1c"
    "kubernetes.io/role/elb" = "1"
  }
}

# 4. Private Subnets (1a, 1c)
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.11.10.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name                              = "11-private-1a"
    "kubernetes.io/role/internal-elb" = "1" # 内部LB用
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.11.11.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name                              = "11-private-1c"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# --- NAT Gateway (Private Subnetから外に出るためのゲートウェイ) ---

# 5. NAT Gateway用のElastic IP
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "11-devsecops-nat-eip" }
}

# 6. NAT Gateway本体 (パブリックサブネットに配置)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1a.id # 設計通り1aに配置

  tags = { Name = "11-devsecops-natgw" }

  # IGWが作成されてから作成するように依存関係を明示
  depends_on = [aws_internet_gateway.main]
}

# --- Route Tables (ルーティングの設定) ---

# 7. Public用ルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "11-public-rt" }
}

# 8. Private用ルートテーブル
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = { Name = "11-private-rt" }
}

# --- Route Table Associations (サブネットとルートテーブルの紐付け) ---

# Public Subnets
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

# Private Subnets
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private.id
}
