locals {
  canonical_owner = "099720109477"
  aws_win_owner   = "801119661308"
}

data "aws_ami" "ubuntu-18_04" {
  most_recent = true
  owners      = [local.canonical_owner]

  filter {
    name   = "name"
    // values = ["ubuntu-minimal/images/*/ubuntu-bionic-18.04-*"]
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
#  aws ec2 describe-images  --filters "Name=owner-id,Values=099720109477" "Name=root-device-type,Values=ebs" "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
data "aws_ami" "ubuntu-20_04" {
  most_recent = true
  owners      = [local.canonical_owner]

  filter {
    name   = "name"
   values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#   values = ["ubuntu-minimal/images/*/ubuntu-focal-20.04-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# aws ec2 describe-images --owners amazon --filters "Name=platform,Values=windows" "Name=root-device-type,Values=ebs" "Name=name,Values=Windows_Server-2019-English-Full-ContainersLatest-*"
data "aws_ami" "windows-2019-ui" {
  most_recent = true
  owners      = [local.aws_win_owner]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-ContainersLatest-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_ami" "windows-2019-core" {
  most_recent = true
  owners      = [local.aws_win_owner]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Core-ContainersLatest-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_ami" "windows-1909" {
  most_recent = true
  owners      = [local.aws_win_owner]

  filter {
    name   = "name"
    values = ["Windows_Server-1909-English-Core-ContainersLatest-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_ami" "windows-2004" {
  most_recent = true
  owners      = [local.aws_win_owner]

  filter {
    name   = "name"
    values = ["Windows_Server-2004-English-Core-ContainersLatest-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_ami" "windows-20h2" {
  most_recent = true
  owners      = [local.aws_win_owner]

  filter {
    name   = "name"
    values = ["Windows_Server-20H2-English-Core-ContainersLatest-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}



output "ubuntu-18_04" {
  value = data.aws_ami.ubuntu-18_04.id
}

output "ubuntu-20_04" {
  value = data.aws_ami.ubuntu-20_04.id
}

output "windows-2019-ui" {
  value = data.aws_ami.windows-2019-ui.id
}

output "windows-2019-core" {
  value = data.aws_ami.windows-2019-core.id
}

output "windows-1909" {
  value = data.aws_ami.windows-1909.id
}

output "windows-2004" {
  value = data.aws_ami.windows-2004.id
}

output "windows-20h2" {
  value = data.aws_ami.windows-20h2.id
}