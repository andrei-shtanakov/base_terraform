provider "aws" {}


data "aws_availability_zones" "working" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_vpcs" "my_vpcs" {}




resource "aws_vpc" "app" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "prod-vpc-10"
  }
}




resource "aws_subnet" "prod_subnet_1" {
  vpc_id            = aws_vpc.app.id
  availability_zone = data.aws_availability_zones.working.names[0]
  cidr_block        = "10.10.1.0/24"
  tags = {
    Name    = "Sub-p-1 in ${data.aws_availability_zones.working.names[0]}"
    Account = "Subnet in Account ${data.aws_caller_identity.current.account_id}"
    Region  = data.aws_region.current.description
  }
}

resource "aws_subnet" "prod_subnet_2" {
  vpc_id            = aws_vpc.app.id
  availability_zone = data.aws_availability_zones.working.names[1]
  cidr_block        = "10.10.2.0/24"
  tags = {
    Name    = "Sub-p-2 in ${data.aws_availability_zones.working.names[1]}"
    Account = "Subnet in Account ${data.aws_caller_identity.current.account_id}"
    Region  = data.aws_region.current.description
  }
}


resource "aws_subnet" "prod_subnet_3" {
  vpc_id            = aws_vpc.app.id
  availability_zone = data.aws_availability_zones.working.names[2]
  cidr_block        = "10.10.3.0/24"
  tags = {
    Name    = "Sub-p-3 in ${data.aws_availability_zones.working.names[2]}"
    Account = "Subnet in Account ${data.aws_caller_identity.current.account_id}"
    Region  = data.aws_region.current.description
  }
}



resource "aws_subnet" "test_subnet_1" {
  vpc_id            = aws_vpc.app.id
  availability_zone = data.aws_availability_zones.working.names[0]
  cidr_block        = "10.10.4.0/24"
  tags = {
    Name    = "Sub-t-1 in ${data.aws_availability_zones.working.names[0]}"
    Account = "Subnet in Account ${data.aws_caller_identity.current.account_id}"
    Region  = data.aws_region.current.description
  }
}

resource "aws_subnet" "test_subnet_2" {
  vpc_id            = aws_vpc.app.id
  availability_zone = data.aws_availability_zones.working.names[1]
  cidr_block        = "10.10.5.0/24"
  tags = {
    Name    = "Sub-t-2 in ${data.aws_availability_zones.working.names[1]}"
    Account = "Subnet in Account ${data.aws_caller_identity.current.account_id}"
    Region  = data.aws_region.current.description
  }
}

resource "aws_subnet" "test_subnet_3" {
  vpc_id            = aws_vpc.app.id
  availability_zone = data.aws_availability_zones.working.names[2]
  cidr_block        = "10.10.6.0/24"
  tags = {
    Name    = "Sub-t-3 in ${data.aws_availability_zones.working.names[2]}"
    Account = "Subnet in Account ${data.aws_caller_identity.current.account_id}"
    Region  = data.aws_region.current.description
  }
}


data "aws_ami" "latest_ubuntu" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_security_group" "prod" {
  name        = "WWW Security Group"
  description = "Open ports for Websever"
  vpc_id      = aws_vpc.app.id 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.app.cidr_block]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "WWW Prod SG"
    Owner = "Andrei Shtanakov"
  }
}


resource "aws_db_instance" "mysqldb" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.20"
  instance_class       = "db.t2.micro"
  name                 = "app_db"
  identifier           = "mysqldb"
  identifier_prefix    = null
  multi_az             = false
  port                 = 3306
  storage_encrypted    = false
  skip_final_snapshot  = true
  snapshot_identifier  = null
  username             = "db_user"
  password             = "12345678"
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = "app-db"
  vpc_security_group_ids = [
    aws_security_group.prod.id
  ]
  tags = {
    Name  = "Application DB"
    Owner = "Andrei Shtanakov"
  }
}



resource "aws_db_instance" "test" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.20"
  instance_class       = "db.t2.micro"
  name                 = "app_db"
  identifier           = "testdb"
  identifier_prefix    = null
  multi_az             = false
  port                 = 3306
  storage_encrypted    = false
  skip_final_snapshot  = true
  snapshot_identifier  = null
  username             = "db_user"
  password             = "12345678"
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = "app-db"
  vpc_security_group_ids = [
    aws_security_group.prod.id
  ]
  tags = {
    Name  = "Test DB"
    Owner = "Andrei Shtanakov"
  }
}


resource "aws_db_subnet_group" "app-db" {
  name                 = "app-db"
  description          = "Subnet prod DB"
  subnet_ids = [aws_subnet.prod_subnet_1.id,
                aws_subnet.prod_subnet_2.id,
                aws_subnet.prod_subnet_3.id,
                aws_subnet.test_subnet_1.id,
                aws_subnet.test_subnet_2.id,
                aws_subnet.test_subnet_3.id
               ]
  tags = {
    Name = "My DB subnet group"
  }

}


resource "aws_instance" "main_ubuntu" {
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.test.id
  vpc_security_group_ids = [aws_security_group.prod.id]
  availability_zone      = data.aws_availability_zones.working.names[0]
  subnet_id              = aws_subnet.prod_subnet_1.id
  user_data              = templatefile("apache_script.tpl", {
    public_ip            = "*",
    fs_name              = aws_efs_file_system.my_efs.id,
    db_address           = aws_db_instance.mysqldb.address,

  })

  tags = {
    Name    = "WWW-main-Server"
    Owner   = "Andrei Shtanakov"
    Project = "Terraform habdled"
  }
  depends_on = [aws_efs_file_system.my_efs]
}



resource "aws_efs_file_system" "my_efs" {
  # (resource arguments)
  creation_token = "my-prod"

  tags = {
    Name = "Shared prod efs"
  }
}

resource "aws_efs_access_point" "prod" {
  file_system_id = aws_efs_file_system.my_efs.id
}

resource "aws_efs_mount_target" "az-a" {

  file_system_id  = aws_efs_file_system.my_efs.id
  subnet_id       = aws_subnet.prod_subnet_1.id
  security_groups = [aws_security_group.prod.id]
}

resource "aws_efs_mount_target" "az-b" {
  file_system_id  = aws_efs_file_system.my_efs.id
  subnet_id       = aws_subnet.prod_subnet_2.id
  security_groups = [aws_security_group.prod.id]
}


resource "aws_efs_mount_target" "az-c" {
  file_system_id  = aws_efs_file_system.my_efs.id
  subnet_id       = aws_subnet.prod_subnet_3.id
  security_groups = [aws_security_group.prod.id]
}

#**********************************************************************

resource "aws_instance" "main_test_ubuntu" {
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.test.id
  vpc_security_group_ids = [aws_security_group.prod.id]
  availability_zone      = data.aws_availability_zones.working.names[0]
  subnet_id              = aws_subnet.test_subnet_1.id
  user_data              = templatefile("apache_script.tpl", {
    public_ip            = "*",
    fs_name              = aws_efs_file_system.my_efs.id,
    db_address           = aws_db_instance.mysqldb.address,

  })

  tags = {
    Name    = "WWW-test-Server"
    Owner   = "Andrei Shtanakov"
    Project = "Terraform habdled"
  }
  depends_on = [aws_efs_file_system.my_test_efs]
}




resource "aws_efs_file_system" "my_test_efs" {
  # (resource arguments)
  creation_token = "my-test"

  tags = {
    Name = "Shared test efs"
  }
}

resource "aws_efs_access_point" "test" {
  file_system_id = aws_efs_file_system.my_test_efs.id
}

resource "aws_efs_mount_target" "test_az-a" {
  file_system_id  = aws_efs_file_system.my_test_efs.id
  subnet_id       = aws_subnet.test_subnet_1.id
  security_groups = [aws_security_group.prod.id]
}

resource "aws_efs_mount_target" "test_az-b" {
  file_system_id  = aws_efs_file_system.my_test_efs.id
  subnet_id       = aws_subnet.test_subnet_2.id
  security_groups = [aws_security_group.prod.id]
}


resource "aws_efs_mount_target" "test_az-c" {
  file_system_id  = aws_efs_file_system.my_test_efs.id
  subnet_id       = aws_subnet.test_subnet_3.id
  security_groups = [aws_security_group.prod.id]
}

#*********************************************************************

resource "aws_key_pair" "test" {
  key_name   = "test"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCfk1mG0oYySWFG0/GQLjKAc4dC/ZlIvL5rHlZqQEfmDBt2Tr5iXwBbiQTv29QPglcDbRB/JlTt9GzjSnsGRh05YIUW1mGflgngNtgq+dDZOEBKZj++A1w5vj63Vltd5PIkgx3++1sKR3PsVZLV0gfj/v+n1g7REZQRVmukJfpdKRBOUk3O0nUxVxo4tXMp2irbUDdwZI4Z/QM1ugoTRKUQcB5V5KfnkaCbZ3GuHigV3aLdjEb1j2UI6feL1aQVwMJw/7nfyWlwuJ4x7r6+hKktb1SopmNRXPl7kKiKQb+AObUQEkfvXdOqdXnpcldJX/SyYxcYGtf5pShzJD7/FOm+TlhJ/Jum13ExL3ga79h4TzFelUsQNVCDFYJxqPLK26PvRPRHCZvVhiRi44FPsZiBY6EbU8M5qbymh44TKmHVQ8gg0Ii2rTeVH6l7HpLP6IE2pX83jUxKJ6egOjVhAtJDUMHq3vF8RW4FnlSDx9oLQ4I/sVOpHhA0RZa+qUwQnDc= user@epam2"
}

output "aws_vpcs" {
  value = data.aws_vpcs.my_vpcs.id
}

output "db_name_dns" {
  value = aws_db_instance.mysqldb.address
}

