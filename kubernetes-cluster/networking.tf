data "aws_availability_zones" "avail_azs" {
  state = "available"
}



# Create 1 public subnets for each AZ within the regional VPC
resource "aws_subnet" "public" {
  count = "${length(data.aws_availability_zones.avail_azs.names)}"
  vpc_id            = aws_vpc.main.id
  availability_zone = "${data.aws_availability_zones.avail_azs.names[count.index]}"
  cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index+1)
  map_public_ip_on_launch = true
 
  tags = {
    Name        = "public-subnet-${data.aws_availability_zones.avail_azs.names[count.index]}-${var.cluster_name}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                    = "1"
  }
}


# Create 1 private subnets for each AZ within the regional VPC
resource "aws_subnet" "private" {
  count = "${length(data.aws_availability_zones.avail_azs.names)}"
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = false
  availability_zone = "${data.aws_availability_zones.avail_azs.names[count.index]}"
  cidr_block = cidrsubnet(var.vpc_cidr, 4, length(data.aws_availability_zones.avail_azs.names) + count.index+1)
 
  tags = {
    Name        = "private-subnet-${data.aws_availability_zones.avail_azs.names[count.index]}-${var.cluster_name}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

resource "aws_subnet" "utility" {
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 253)
  availability_zone       = element(data.aws_availability_zones.avail_azs.names, 1)
  tags = {
    Name = "utility"
  }
}


# Create an Internet Gateway.

resource "aws_internet_gateway" "igw" {
 vpc_id = aws_vpc.main.id
}

# Create Nat gateway & EIP

#resource "aws_eip" "eip" {
#  vpc = true
#}

#resource "aws_nat_gateway" "natgw" {
#  allocation_id = aws_eip.eip.id
#  subnet_id     = aws_subnet.utility.id
#}

#resource "aws_route" "natgw" {
#  route_table_id         = aws_route_table.private-rt.id
#  destination_cidr_block = "0.0.0.0/0"
#  nat_gateway_id         = aws_nat_gateway.natgw.id
#  depends_on             = [aws_route_table.private-rt]
#}


# Create a Public Route Table
 
resource "aws_route_table" "public-rt" {
 vpc_id = aws_vpc.main.id
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.igw.id
 }
 tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
 }
}


# Associating Public Subnets to the Second Route Table

resource "aws_route_table_association" "public_subnet_asso" {
 count = length(data.aws_availability_zones.avail_azs.names)
 subnet_id      = element(aws_subnet.public[*].id, count.index)
 route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "utility_subnet_asso" {
 subnet_id      = aws_subnet.utility.id
 route_table_id = aws_route_table.public-rt.id
}


# Create a Private Route Table
 
resource "aws_route_table" "private-rt" {
 vpc_id = aws_vpc.main.id
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}


# Associating Public Subnets to Private Route Table

resource "aws_route_table_association" "private_subnet_asso" {
 count = length(data.aws_availability_zones.avail_azs.names)
 subnet_id      = element(aws_subnet.private[*].id, count.index)
 route_table_id = aws_route_table.private-rt.id
}

