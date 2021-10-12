```powershell
curl.exe -sfLO https://releases.hashicorp.com/terraform/1.0.8/terraform_1.0.8_windows_amd64.zip
expand-archive terraform_1.0.8_windows_amd64.zip
new-item -type directory -path ~\windows\tools\ -force
copy-item terraform_1.0.8_windows_amd64/terraform.exe ~\windows\tools\terraform.exe
$env:PATH+=";~\windows\tools"
```

```powershell
git clone https://github.com/rosskirkpat/terraform-modules.git
cd terraform-modules/rancher_windows_cluster
../login.ps1 $RANCHER_SERVER $USER $PASS
copy-item default.auto.tfvars.example default.auto.tfvars
code default.auto.tfvars
```

### If you don't have an existing ec2 key pair in the PEM format, don't worry
### We will create one and import the PEM key to aws 
### PEM is required for decrpyting the password of EC2 Windows nodes 

```powershell
terraform init # required to initialize the modules and providers
terraform plan # prints out what terraform will do when then apply is run
terraform apply # applies the terraform plan/state and creates resources
terraform destroy # will destroy every terraform resource that was created
```