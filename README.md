##terraform-aws-opsmanager

This terraform script just automize most of described task on [Pcf on AWS documentation](http://cf-p1-docs-acceptance.cfapps.io/pivotalcf/customizing/pcf-aws-component-config.html#pcfaws-s3)

#Prerequies

* You **must** being using at least terraform version 0.4.0. [terraform](https://terraform.io)

```
$ terraform -v
Terraform v0.4.0
```

* You need an AWS account, admin account is good enough.
 
 [Not Required] You can create ``` pcf-user ``` [PCF IAM USER](http://cf-p1-docs-acceptance.cfapps.io/pivotalcf/customizing/pcf-aws-component-config)

* Need to increase AWS ressource limitation [Instances Limit](http://cf-p1-docs-acceptance.cfapps.io/pivotalcf/customizing/pcf-aws-component-config.html#instance-limit)



#Deploy OpsManager

* Clone this repository

* Edit `terraform.tfvars` using your text editor and fill out the variables with your own values (AWS credentials, AWS region, etc) 

* Finally run the deploy command
```bash
make plan
make apply
```




