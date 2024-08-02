Terraform Project: VPC with Private Subnets, Bastion Host, NAT Gateway, Load Balancers, and Elastic IPs
This project demonstrates how to create a VPC with servers in private subnets, a Bastion Host, NAT gateway, load balancers, target groups, and elastic IPs across two availability zones using Terraform.

Prerequisites
Install Terraform on your local machine.
Install Visual Studio Code on your local machine.
Steps to Work on the Repository
Step 1: Clone the Repository
git clone <repository-url>
cd <repository-folder>
Step 2: Open the Files in Visual Studio Code
Step 3: Edit Variables and Names
Edit the variables and names in the .tf files according to your requirements.

Step 4: Open Terminal in Visual Studio Code
Navigate to the folder containing the Terraform files and open the terminal.

Step 5: Configure AWS CLI

aws configure
Enter the key-value pairs and specify the location.

Terraform Stages
Stage 1: Initialize Terraform

terraform init
This command initializes a working directory containing Terraform configuration files.

Stage 2: Validate Terraform Configuration

terraform validate
This command verifies the correctness of Terraform configuration files.

Stage 3: Plan Terraform Changes

terraform plan
This command creates a plan of the changes required to match your resources to the configuration.

Stage 4: Apply Terraform Changes

terraform apply
This command applies the changes to make your infrastructure match the configuration.

Verify Resources in AWS Console
After applying the changes, check the AWS console to verify the creation of the following resources:

VPC
Subnets
Internet Gateway (IGW)
NAT Gateways
Elastic IPs
EC2 instances in private subnets
Bastion host in the public subnet with a public IP
Accessing Instances via Bastion Host

Step 1: Copy PEM File to Bastion Host

chmod 400 example.pem
scp -i example.pem example.pem ec2-user@<bastion-host-ip>:/home/ec2-user/

Step 2: Connect to Bastion Host

ssh -i example.pem ec2-user@<bastion-host-ip>
ls

Step 3: Copy PEM File to Private Instances

scp -i example.pem example.pem ec2-user@<private-ip1>:/home/ec2-user/
scp -i example.pem example.pem ec2-user@<private-ip2>:/home/ec2-user/

Step 4: Connect to Private Instances and Install Nginx
For Private Instance 1

ssh -i example.pem ec2-user@<private-ip1>
ls
sudo yum update -y
sudo yum install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo nano /usr/share/nginx/html/index.html
sudo systemctl restart nginx


For Private Instance 2

ssh -i example.pem ec2-user@<private-ip2>
ls
sudo yum update -y
sudo yum install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo nano /usr/share/nginx/html/index.html
sudo systemctl restart nginx

Step 5: Verify Load Balancer
Open the Load Balancer DNS name in a browser. Refresh to see both servers running on private instances.

Stage 6: Destroy Terraform Resources
To terminate resources managed by Terraform, use the command:

Terraform destroy
This command terminates all resources specified in your Terraform state.
