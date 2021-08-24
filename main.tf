provider "aws" {}


data "aws_availability_zones" "working" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_vpcs" "my_vpcs" {}


#************* Default vps ******************************************


resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}


resource "aws_default_subnet" "default-a" {
  availability_zone = data.aws_availability_zones.working.names[0]

  tags = {
    Name = "Default subnet for eu-central-1a"
  }
}

resource "aws_default_subnet" "default-b" {
  availability_zone = data.aws_availability_zones.working.names[1]

  tags = {
    Name = "Default subnet for eu-central-1b"
  }
}

resource "aws_default_subnet" "default-c" {
  availability_zone = data.aws_availability_zones.working.names[2]

  tags = {
    Name = "Default subnet for eu-central-1c"
  }
}
#**********************************************************************

data "aws_security_group" "prod" {
  filter {
    name   = "tag:Name"
    values = ["Prod_SecurityGroup"]
  }
}

data "aws_security_group" "def" {
  filter {
    name   = "tag:Name"
    values = ["Def_SecurityGroup"]
  }
}


data "aws_vpc" "prod" {
  filter {
    name   = "tag:Name"
    values = ["prod-vpc-10"]
  }
}

data "aws_vpc" "test" {
  filter {
    name   = "tag:Name"
    values = ["test-vpc-20"]
  }
}



#***************** PROD public SUBNETS *******************************


data "aws_subnet" "prod_public-a" {
  filter {
    name   = "tag:Name"
    values = ["Sub-public-1 in ${data.aws_availability_zones.working.names[0]}"]
  }
}

data "aws_subnet" "prod_public-b" {
  filter {
    name   = "tag:Name"
    values = ["Sub-public-2 in ${data.aws_availability_zones.working.names[1]}"]
  }
}


data "aws_subnet" "prod_public-c" {
  filter {
    name   = "tag:Name"
    values = ["Sub-public-3 in ${data.aws_availability_zones.working.names[2]}"]
  }
}


#***************** PROD private SUBNETS *******************************


data "aws_subnet" "prod_private-a" {
  filter {
    name   = "tag:Name"
    values = ["Sub-private-1 in ${data.aws_availability_zones.working.names[0]}"]
  }
}

data "aws_subnet" "prod_private-b" {
  filter {
    name   = "tag:Name"
    values = ["Sub-private-2 in ${data.aws_availability_zones.working.names[1]}"]
  }
}


data "aws_subnet" "prod_private-c" {
  filter {
    name   = "tag:Name"
    values = ["Sub-private-3 in ${data.aws_availability_zones.working.names[2]}"]
  }
}

#***************** PROD DB SUBNETS ***********************************

data "aws_subnet" "prod_dbase-a" {
  filter {
    name   = "tag:Name"
    values = ["Sub-db-1 in ${data.aws_availability_zones.working.names[0]}"]
  }
}

data "aws_subnet" "prod_dbase-b" {
  filter {
    name   = "tag:Name"
    values = ["Sub-db-2 in ${data.aws_availability_zones.working.names[1]}"]
  }
}


data "aws_subnet" "prod_dbase-c" {
  filter {
    name   = "tag:Name"
    values = ["Sub-db-3 in ${data.aws_availability_zones.working.names[2]}"]
  }
}



resource "aws_db_instance" "prod-sql-db" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.20"
  instance_class       = "db.t2.micro"
  name                 = "app_db"
  identifier           = "prod-sql-db"
  identifier_prefix    = null
  multi_az             = false
  port                 = 3306
  storage_encrypted    = false
  skip_final_snapshot  = true
  snapshot_identifier  = null
  username             = "db_user"
  password             = "12345678"
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = "for-prod-db"
  vpc_security_group_ids = [
    data.aws_security_group.prod.id

  ]
  tags = {
    Name = "prod-sql-db"
  }
  depends_on = [aws_db_subnet_group.for-prod-db]
}



resource "aws_db_subnet_group" "for-prod-db" {
  name                 = "for-prod-db"
  description          = "Subnet for DB"
  subnet_ids = [data.aws_subnet.prod_dbase-a.id,
                data.aws_subnet.prod_dbase-b.id,
                data.aws_subnet.prod_dbase-c.id
               ]
  tags = {
    Name = "My def DB subnet group"
  }

}


resource "aws_network_interface" "prod1" {
  subnet_id   = data.aws_subnet.prod_public-a.id
  security_groups = [data.aws_security_group.prod.id]
  tags = {
    Name = "primary_network_interface"
  }
}


resource "aws_network_interface" "prod2" {
  subnet_id   = data.aws_subnet.prod_public-a.id
  security_groups = [data.aws_security_group.prod.id]
  tags = {
    Name = "secondary_network_interface"
  }
}


data "aws_ami" "latest_ubuntu" {
  owners      = ["982781670762"]
  most_recent = true
  filter {
    name   = "name"
    values = ["Back-End"]
  }
}



resource "aws_instance" "my_def_ubuntu" {
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.test-1.id
  availability_zone      = data.aws_availability_zones.working.names[0]
  user_data              = templatefile("init.tpl", {
    public_ip            = "*",
    fs_name              = aws_efs_file_system.prod_efs.id,
    db_address           = aws_db_instance.prod-sql-db.address,
  })
  network_interface {
    network_interface_id = aws_network_interface.prod1.id
    device_index         = 0
  }
  tags = {
    Name    = "Def-Server-1"
    Owner   = "Andrei Shtanakov"
    Project = "Terraform habdled"
  }
  depends_on = [aws_efs_file_system.prod_efs]
}



resource "aws_instance" "my_def_ubuntu2" {
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.test-1.id
  availability_zone      = data.aws_availability_zones.working.names[0]
  user_data              = templatefile("attach.tpl", {
    public_ip            = "*",
    fs_name              = aws_efs_file_system.prod_efs.id,
    db_address           = aws_db_instance.prod-sql-db.address,
  })
  network_interface {
    network_interface_id = aws_network_interface.prod2.id
    device_index         = 0
  }
  tags = {
    Name    = "Def-Server-2"
    Owner   = "Andrei Shtanakov"
    Project = "Terraform habdled"
  }
  depends_on = [aws_efs_file_system.prod_efs, aws_instance.my_def_ubuntu]
}

#*********************************************************************



resource "aws_default_subnet" "default_az-a" {
  availability_zone =  data.aws_availability_zones.working.names[0]

  tags = {
    Name = "Default subnet a"
  }
}

resource "aws_default_subnet" "default_az-b" {
  availability_zone =  data.aws_availability_zones.working.names[1]

  tags = {
    Name = "Default subnet b"
  }
}



resource "aws_efs_file_system" "prod_efs" {
  # (resource arguments)
  creation_token = "my-def-product"

  tags = {
    Name = "MyDefProduct"
  }
}
resource "aws_efs_access_point" "prod" {
  file_system_id = aws_efs_file_system.prod_efs.id
}

resource "aws_efs_mount_target" "prod-efs-1" {
  file_system_id  = aws_efs_file_system.prod_efs.id
  subnet_id       = data.aws_subnet.prod_public-a.id
  security_groups = [data.aws_security_group.prod.id]
}

resource "aws_efs_mount_target" "prod-efs-2" {
  file_system_id  = aws_efs_file_system.prod_efs.id
  subnet_id       = data.aws_subnet.prod_public-b.id
  security_groups = [data.aws_security_group.prod.id]

}

resource "aws_efs_mount_target" "prod-efs-3" {
  file_system_id  = aws_efs_file_system.prod_efs.id
  subnet_id       = data.aws_subnet.prod_public-c.id
  security_groups = [data.aws_security_group.prod.id]

}


#**********************************************************************

#*********************************************************************

resource "aws_key_pair" "test-1" {
  key_name   = "test-1"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCfk1mG0oYySWFG0/GQLjKAc4dC/ZlIvL5rHlZqQEfmDBt2Tr5iXwBbiQTv29QPglcDbRB/JlTt9GzjSnsGRh05YIUW1mGflgngNtgq+dDZOEBKZj++A1w5vj63Vltd5PIkgx3++1sKR3PsVZLV0gfj/v+n1g7REZQRVmukJfpdKRBOUk3O0nUxVxo4tXMp2irbUDdwZI4Z/QM1ugoTRKUQcB5V5KfnkaCbZ3GuHigV3aLdjEb1j2UI6feL1aQVwMJw/7nfyWlwuJ4x7r6+hKktb1SopmNRXPl7kKiKQb+AObUQEkfvXdOqdXnpcldJX/SyYxcYGtf5pShzJD7/FOm+TlhJ/Jum13ExL3ga79h4TzFelUsQNVCDFYJxqPLK26PvRPRHCZvVhiRi44FPsZiBY6EbU8M5qbymh44TKmHVQ8gg0Ii2rTeVH6l7HpLP6IE2pX83jUxKJ6egOjVhAtJDUMHq3vF8RW4FnlSDx9oLQ4I/sVOpHhA0RZa+qUwQnDc= user@epam2"
  tags = {
    Name    = "Key-test-1"
  }
}




output "aws_vpcs" {
  value = data.aws_vpcs.my_vpcs.id
}

output "db_name_dns" {
  value = aws_db_instance.prod-sql-db.address
}

