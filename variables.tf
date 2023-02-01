variable "network_interface_id" {
  type = string
  default = "network_id_from_aws"
}

variable "ami" {
    type = string
    default = "ami-06c39ed6b42908a36"
}

variable "instance_type" {
    type = string
    default = "t2.micro"
}