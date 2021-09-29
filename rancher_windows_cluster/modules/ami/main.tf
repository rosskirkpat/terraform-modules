# Use latest SLES 15 SP3
data "aws_ami" "sles-15_SP3" {
  most_recent = true
  owners      = ["013907871322"] # SUSE

  filter {
    name   = "name"
    values = ["suse-sles-15-sp3*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_ami" "ubuntu-18_04" {
  most_recent = true
  owners      = ["099720109477"]


  filter {
    name   = "name"
#   values = ["*ubuntu-bionic-18.04-*"]
    values = ["ubuntu-minimal/images/*/ubuntu-bionic-18.04-*"]
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

data "aws_ami" "ubuntu-20_04" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
#   values = ["*ubuntu-bionic-18.04-*"]
    values = ["ubuntu-minimal/images/*/ubuntu-focal-20.04-*"]
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

# aws ec2 describe-images --owners amazon --filters "Name=platform,Values=windows" "Name=root-device-type,Values=ebs" "Name=name,Values=Windows*2019*Containers*"
data "aws_ami" "windows-2019" {
  most_recent = true
  owners      = ["801119661308"]

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

# aws ec2 describe-images --owners amazon --filters "Name=platform,Values=windows" "Name=root-device-type,Values=ebs" "Name=name,Values=Windows*2019*Containers*"
data "aws_ami" "windows-2022" {
  most_recent = true
  owners      = ["801119661308"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-ContainersLatest-*"]
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

output "sles-15_SP3" {
  value = data.aws_ami.sles-15_SP3.id
}

output "ubuntu-18_04" {
  value = data.aws_ami.ubuntu-18_04.id
}

output "ubuntu-20_04" {
  value = data.aws_ami.ubuntu-20_04.id
}

output "windows-2019" {
  value = data.aws_ami.windows-2019.id
}

output "windows-2022" {
  value = data.aws_ami.windows-2022.id
}
