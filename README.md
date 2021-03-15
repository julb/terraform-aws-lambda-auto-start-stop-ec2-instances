# terraform-aws-lambda-auto-start-stop-ec2-instances

A terraform module to start or stop EC2 instances on a periodic basis.

In order to save some AWS costs, it is usual to stop Non-Production assets out of business hours.
This module enables to stop or start instances at the time you need.
Please note that EC2 instances managed by an Auto Scaling Group are excluded. See [julb/terraform-aws-lambda-auto-start-stop-ec2-autoscalinggroups](https://github.com/julb/terraform-aws-lambda-auto-start-stop-ec2-autoscalinggroups) module to manage these ones.

See related modules:

- [julb/terraform-aws-lambda-auto-start-stop-ec2-instances](https://github.com/julb/terraform-aws-lambda-auto-start-stop-ec2-instances)
- [julb/terraform-aws-lambda-auto-start-stop-ec2-autoscalinggroups](https://github.com/julb/terraform-aws-lambda-auto-start-stop-ec2-autoscalinggroups)
- [julb/terraform-aws-lambda-auto-start-stop-rds-instances](https://github.com/julb/terraform-aws-lambda-auto-start-stop-rds-instances)
- [julb/terraform-aws-lambda-auto-start-stop-cloudwatch-alarms](https://github.com/julb/terraform-aws-lambda-auto-start-stop-cloudwatch-alarms)


## Usage

- Stop EC2 instances

```hcl
module "stop_ec2_instances" {
  source              = "github.com/julb/terraform-aws-lambda-auto-start-stop-ec2-instances"
  name                = "StopEc2Instances"
  schedule_expression = "cron(0 0 ? * FRI *)"
  action              = "stop"
  tags                = { "custom:tag" : "someValue" }
  lookup_resource_tag = {
    key   = "ops:env"
    value = "non-prod"
  }
}
```

- Start EC2 instances

```hcl
module "start_ec2_instances" {
  source              = "github.com/julb/terraform-aws-lambda-auto-start-stop-ec2-instances"
  name                = "StartEc2Instances"
  schedule_expression = "cron(0 8 ? * MON *)"
  action              = "start"
  tags                = { "custom:tag" : "someValue" }
  lookup_resource_tag = {
    key   = "ops:env"
    value = "non-prod"
  }
}
```

## Module Input Variables

| Name                    | Type                             | Default    | Description                                                                                                                 |
| ----------------------- | -------------------------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| schedule_expression     | string                           |  `Not Set` |  The CloudWatch Schedule Expression to trigger the Lambda. Can be a CRON expression for example. _Required_.                |
| name                    | string                           |  `Not Set` |  The name of the lambda to create. _Required_.                                                                              |
| tags                    | map(string)                      |  `{}`      |  The tags to assign to the created resources.                                                                               |
| custom_iam_role_arn     | string                           |  `Not Set` |  The IAM role to assign to the Lambda. If not specified, a role with appropriate permissions will be created.               |
| action                  | string                           |  `Not Set` |  The action to perform. Valid values are `enable`,`disable`. (`start`, `stop` are supported aliases as well). **Required**. |
| lookup_resource_tag     | object{key=string, value=string} |  `Not Set` |  The tags to filter on to look for EC2 instances within the regions. **Required**.                                          |
| lookup_resource_regions | list(string)                     |  `Not Set` | Look for EC2 instances in the specified regions. By default, it uses the region in which the lambda is deployed.            |

## Outputs

| Name                  | Type   | Description                                                                                  |
| --------------------- | ------ | -------------------------------------------------------------------------------------------- |
| lambda_function_name  | string |  The Lambda function name.                                                                   |
| lambda_arn            | ARN    |  The Lambda Amazon Resource Identifier.                                                      |
| lambda_iam_role_arn   | ARN    |  The IAM Role Amazon Resource Identifier assigned to the Lambda.                             |
| lambda_log_group_name | string |  The CloudWatch Log Group name in which the Lambda push logs.                                |
| lambda_log_group_arn  | ARN    |  The CloudWatch Log Group Amazon Resource Identifier assigned in which the Lambda push logs. |

## Contributing

This project is totally open source and contributors are welcome.

When you submit a PR, please ensure that the python code is well formatted and linted.

```
$ make format
$ make lint
$ make test
```
