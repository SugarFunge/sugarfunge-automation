resource "aws_security_group" "sf-sg-public-01" {
  name        = "sf-sg-public-01"
  description = "SugarFunge public Security Group"
  vpc_id      = aws_vpc.sf-vpc-01.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.prefix}-sg-public-01"
  }
}

resource "aws_security_group" "sf-sg-private-01" {
  name        = "sf-sg-private-01"
  description = "SugarFunge public Security Group"
  vpc_id      = aws_vpc.sf-vpc-01.id

  ingress {
    description      = "PublicSG"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    security_groups  = [aws_security_group.sf-sg-public-01.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.prefix}-sg-private-01"
  }
}

resource "aws_instance" "sf-instances" {
  for_each        = var.resources
  ami             = "ami-09e67e426f25ce0d7"
  instance_type   = each.value.instance_type
  key_name        = var.key_name
  subnet_id       = each.value.is_public ? aws_subnet.sf-subnet-public-01.id : aws_subnet.sf-subnet-private-01.id
  security_groups = each.value.is_public ? [aws_security_group.sf-sg-public-01.id] : [aws_security_group.sf-sg-private-01.id]

  tags = {
    Name = "${var.prefix}-${each.value.name}-0${each.value.version}"
  }
}

resource "local_file" "AnsibleInventory" {
  content = templatefile("templates/inventory.tmpl",
    {
      nginx   = aws_instance.sf-instances["nginx"],
      api     = aws_instance.sf-instances["api"],
      node_01 = aws_instance.sf-instances["node01"],
      node_02 = aws_instance.sf-instances["node02"],
      ipfs    = aws_instance.sf-instances["ipfs"],
    }
  )
  filename = "../../ansible/inventory.ini"
}

resource "local_file" "AnsibleNginx" {
  content = templatefile("templates/nginx_main.tmpl",
    {
      api     = aws_instance.sf-instances["api"].private_ip,
      node_01 = aws_instance.sf-instances["node01"].private_ip,
      node_02 = aws_instance.sf-instances["node02"].private_ip,
      ipfs    = aws_instance.sf-instances["ipfs"].private_ip,
    }
  )
  filename = "../../ansible/playbooks/vars/nginx_main.yml"
}
