# ecs.tf

# ... (檔案其他部分保持不變) ...

# 數據源：獲取 ECS 優化 AMI (Amazon Linux 2)
# *** 註解掉此區塊，因為自動查詢失敗 ***
/*
data "aws_ami" "ecs_optimized_ami" {
  most_recent = true
  owners      = ["amazon"] # AWS 官方 AMI
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-gp2"] # 查找 ECS 優化 Amazon Linux 2 AMI
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
*/

# 資源：EC2 容器實例 (將運行 Docker 容器的 EC2 虛擬機)
resource "aws_instance" "ecs_container_instance" {
  # *** 將 ami 替換為你手動查到的 AMI ID ***
  ami           = "ami-xxxxxxxxxxxxxxxxx" # <-- 請將此處替換為你在 AWS 控制台查到的實際 AMI ID！
  instance_type = "t3.small"                        # 實例類型，根據需求調整
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ecs_instance_profile.name

  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.my_ec2_cluster.name} >> /etc/ecs/ecs.config
              sudo yum update -y
              sudo amazon-linux-extras install -y docker
              sudo systemctl enable docker --now
              sudo usermod -a -G docker ec2-user
              sudo systemctl enable ecs --now
              EOF

  tags = {
    Name = "ECS-Container-Instance-${var.aws_region}"
  }
}

# ... (檔案其他部分保持不變) ...
