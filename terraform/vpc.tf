# vpc.tf - 簡化版

# 數據源：獲取可用區列表
data "aws_availability_zones" "available" {
  state = "available"
}

# 資源：虛擬私有雲 (VPC)
resource "aws_vpc" "app_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "my-app-vpc-${var.aws_region}"
  }
}

# 資源：公有子網 (ECS EC2 實例將直接部署在這裡)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.app_vpc.cidr_block, 8, 0) # 例如 10.0.0.0/24
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true # 允許自動分配公有 IP，讓 EC2 實例可以直接訪問網際網路
  tags = {
    Name = "my-app-public-subnet-${var.aws_region}"
  }
}

# 資源：網際網路閘道 (Internet Gateway)
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "my-app-igw-${var.aws_region}"
  }
}

# 資源：公有路由表 (將公有子網流量導向 IGW)
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }
  tags = {
    Name = "my-app-public-route-table-${var.aws_region}"
  }
}

# 資源：路由表關聯 (將公有子網與公有路由表關聯)
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# 資源：安全組 (Security Group，控制進出 EC2 實例和 ECS 任務的流量)
resource "aws_security_group" "app_sg" {
  name        = "my-app-security-group-${var.aws_region}"
  description = "Allow inbound traffic to ECS EC2 instances"
  vpc_id      = aws_vpc.app_vpc.id

  # 允許來自任何地方的 8080 Port 入站流量 (你的應用程式 Port)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 允許所有 IP 訪問 (根據你的需求限制來源 IP 範圍)
    description = "Allow HTTP traffic on port 8080" # *** 已修正為英文描述 ***
  }

  # 允許所有出站流量
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-app-sg-${var.aws_region}"
  }
}

# 資源：彈性 IP (EIP，用於 NAT Gateway)
# 注意：此資源在簡化版 VPC 中不再直接使用於 NAT Gateway，
# 但如果你的 EC2 實例需要固定公有 IP，則可以保留並關聯
# 為了避免錯誤，我將其移除，因為簡化版不再需要 NAT Gateway
# 如果你需要為 EC2 實例分配固定 IP，請使用 aws_eip_association
/*
resource "aws_eip" "nat_gateway_eip" {
  # 將 'vpc = true' 改為 'domain = "vpc"'
  domain = "vpc" # 修正棄用警告
  tags = {
    Name = "my-app-nat-eip-${var.aws_region}"
  }
}
*/
