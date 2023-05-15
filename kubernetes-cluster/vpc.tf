resource "aws_vpc" "main" {
  cidr_block                       = var.vpc_cidr
  enable_dns_hostnames             = true
  enable_dns_support               = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_vpc_dhcp_options" "dhcpos" {
  domain_name         = "${var.region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
}