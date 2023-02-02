# Autoscaling Group, Application Load Balancer and EC2 Instance Deploy on AWS with Terraform

## Prerequisites
1. Terraform --> 1.2.9
2. AWS Account --> Free Tier is fine
3. Basic Knowledge about AWS Services


## Steps
1. Install Terraform following the steps here (https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
2. Open AWS account and get programmatic access with generating access key (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html).
3. Put the access key in a place for Terraform to access (e.g. ~/.aws/credentials)
4. Clone the repository
5. Terraform validate & init & plan & apply
6. Follow the Terraform logs and AWS EC2 dashboard to check deployment status.


Resulting topology is below. Application Load Balancer (ALB), Auto Scaling Group (ASG) and Elastic Compute Cloud (EC2) are the main components of this deployment. IAM, security groups, ALB listeners, target groups, launch configurations and autoscaling policies are the others.

![image](https://user-images.githubusercontent.com/33878173/216153706-ff67489d-5093-4f59-b015-5903763dfeee.png)

A more complete discussion on IaC and AWS deployment automation is available in my Medium blog on --> https://medium.com/@emrah-t/aws-asg-alb-ec2-deployment-with-terraform-8e01055ff9fb
