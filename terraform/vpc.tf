# vpc.tf

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

# 資源：公有子網 (用於 NAT Gateway)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.app_vpc.cidr_block, 8, 0) # 例如 10.0.0.0/24
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true # 允許自動分配公有 IP
  tags = {
    Name = "my-app-public-subnet-${var.aws_region}"
  }
}

# 資源：私有子網 (用於 ECS EC2 實例和任務)
resource "aws_subnet" "private_subnets" {
  count             = 2 # 在兩個可用區中創建私有子網
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.app_vpc.cidr_block, 8, count.index + 1) # 例如 10.0.1.0/24, 10.0.2.0/24
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "my-app-private-subnet-${count.index}-${var.aws_region}"
  }
}

# 資源：網際網路閘道 (Internet Gateway)
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "my-app-igw-${var.aws_region}"
  }
}

# 資源：彈性 IP (EIP，用於 NAT Gateway)
resource "aws_eip" "nat_gateway_eip" {
  vpc = true
  tags = {
    Name = "my-app-nat-eip-${var.aws_region}"
  }
}

# 資源：NAT 閘道 (NAT Gateway，允許私有子網出站訪問網際網路)
resource "aws_nat_gateway" "app_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "my-app-nat-gateway-${var.aws_region}"
  }
  # 確保在 NAT Gateway 創建後才繼續
  depends_on = [aws_internet_gateway.app_igw]
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

# 資源：私有路由表 (將私有子網流量導向 NAT Gateway)
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app_nat_gateway.id
  }
  tags = {
    Name = "my-app-private-route-table-${var.aws_region}"
  }
}

# 資源：路由表關聯 (將公有子網與公有路由表關聯)
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# 資源：路由表關聯 (將私有子網與私有路由表關聯)
resource "aws_route_table_association" "private_subnet_association" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# 資源：安全組 (Security Group，控制進出 EC2 實例和 ECS 任務的流量)
resource "aws_security_group" "app_sg" {
  name        = "my-app-security-group-${var.aws_region}"
  description = "允許應用程式流量進出 ECS EC2 實例"
  vpc_id      = aws_vpc.app_vpc.id

  # 允許來自任何地方的 8080 Port 入站流量 (你的應用程式 Port)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 根據你的需求限制來源 IP 範圍
    description = "允許應用程式 Port 8080 流量"
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
