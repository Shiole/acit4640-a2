variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

resource "aws_instance" "a02_db" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  key_name        = var.ssh_key_name
  subnet_id       = aws_subnet.a02_priv_subnet.id
  security_groups = [aws_security_group.a02_priv_sg.id]
  tags = {
    Name    = "a02_db"
    Project = var.project_name
    Type    = "db"
  }
}

resource "aws_instance" "a02_backend" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  key_name        = var.ssh_key_name
  subnet_id       = aws_subnet.a02_priv_subnet.id
  security_groups = [aws_security_group.a02_priv_sg.id]
  tags = {
    Name    = "a02_backend"
    Project = var.project_name
    Type    = "backend"
  }
}

resource "aws_instance" "a02_web" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  key_name        = var.ssh_key_name
  subnet_id       = aws_subnet.a02_pub_subnet.id
  security_groups = [aws_security_group.a02_pub_sg.id]
  tags = {
    Name    = "a02_web"
    Project = var.project_name
    Type    = "web"
  }
}

resource "local_file" "inventory_file" {
  content = <<EOF
db:
  hosts:
    ${aws_instance.a02_db.public_dns}

backend:
  hosts:
    ${aws_instance.a02_backend.public_dns}

web:
  hosts:
    ${aws_instance.a02_web.public_dns}
EOF

  filename = "../service/inventory/webservers.yml"
}

resource "local_file" "nginx_config" {
  content = <<EOF
server {
        listen        80;
        server_name   ${aws_instance.a02_web.public_dns} "";

        root /usr/share/nginx/html;

        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                try_files $uri $uri/ =404;
        }

        location /json {
                proxy_pass http://${aws_instance.a02_backend.private_ip}:5000;
        }
}
EOF

  filename = "../service/templates/default"
}

resource "local_file" "backend_config" {
  content = <<EOF
[database]
MYSQL_HOST = ${aws_instance.a02_db.private_ip}
MYSQL_PORT = 3306
MYSQL_DB = backend
MYSQL_USER = a02
MYSQL_PASSWORD = password
EOF

  filename = "../service/templates/backend/backend.conf"
}

resource "local_file" "instances" {
  content  = <<EOF
#!/bin/bash

db_ec2_id=${aws_instance.a02_db.id}
backend_ec2_id=${aws_instance.a02_backend.id}
web_ec2_id=${aws_instance.a02_web.id}
web_dns=${aws_instance.a02_web.public_dns}

EOF
  filename = "../instances.sh"
}
