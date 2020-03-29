resource "aws_vpc" "myVpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "myVpc"
  }
}

resource "aws_internet_gateway" "myInternetGateway" {
  vpc_id = "${aws_vpc.myVpc.id}"

  tags = {
    Name = "myInternetGateway"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.myVpc.id}"
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "us-west-2d"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = "${aws_vpc.myVpc.id}"
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "us-west-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "PrivateSubnet"
  }
}

# Routing table for public subnets
resource "aws_route_table" "rtblPublic" {
  vpc_id = "${aws_vpc.myVpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.myInternetGateway.id}"
  }

  tags = {
    Name = "rtblPublic"
  }
}

resource "aws_route_table_association" "route" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.rtblPublic.id}"
}

# Elastic IP for NAT gateway
resource "aws_eip" "nat" {
}

# NAT Gateway
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public_subnet.id}"
}

# Routing table for private subnets
resource "aws_route_table" "rtblPrivate" {
  vpc_id = "${aws_vpc.myVpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat-gw.id}"
  }

  tags = {
    Name = "rtblPrivate"
  }
}

resource "aws_route_table_association" "private_route" {
  subnet_id      = "${aws_subnet.private_subnet.id}"
  route_table_id = "${aws_route_table.rtblPrivate.id}"
}