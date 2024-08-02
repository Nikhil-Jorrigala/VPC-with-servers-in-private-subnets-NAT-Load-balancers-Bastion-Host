variable "cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type = list(string)
  description = "Public subnet cidr values"
  default = [ "10.0.1.0/24","10.0.2.0/24" ]
}

variable "private_subnet_cidrs" {
  type = list(string)
  description = "Private subnet cidr values"
  default = [ "10.0.3.0/24","10.0.4.0/24" ]
}

variable "azs" {
  type = list(string)
  description = "Availability Zones"
  default = [ "us-east-2a","us-east-2b" ]

}


variable "ami_id" {
  description = "The ami id for ec2 instances"
  type = string
  default = "ami-0c11a84584d4e09dd" # add your ami id


}


variable "instance_type" {
  description = "The instance type of EC2 Instances"
  type = string
  default = "t2.micro"

}

variable "key_name" {
  description = "the key name for ssh access"
  type = string
  default = "aws-ohio" # add your pem or ppk file here 
  
}

