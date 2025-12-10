resource "aws_vpc" "main" { # VPC 생성
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "TIB-vpc"
  }
}

resource "aws_internet_gateway" "igw" { # igw 생성
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "TIB-igw"
  }
}

resource "aws_subnet" "public_1" { # AZ1 Public
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "TIB-public-subnet-1"
  }
}

resource "aws_subnet" "private_1" { # AZ1 Private
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "TIB-private-subnet-1"
  }
}

resource "aws_subnet" "public_2" { # AZ2 Public
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.30.0/24"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "TIB-public-subnet-2"
  }
}

resource "aws_subnet" "private_2" { # AZ2 Private
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.40.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "TIB-private-subnet-2"
  }
}

resource "aws_eip" "nat_1" { # NAT1 EIP
  vpc = true
}

resource "aws_nat_gateway" "nat_1" { # NAT1 Gateway
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "TIB-nat-1"
  }
}

resource "aws_eip" "nat_2" { # NAT2 EIP
  vpc = true
}

resource "aws_nat_gateway" "nat_2" { # NAT2 Gateway
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id

  tags = {
    Name = "TIB-nat-2"
  }
}

resource "aws_route_table" "public" { # Public Route Table
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "TIB-public-rt"
  }
}

resource "aws_route_table" "private_1" { # Private Route Table AZ1
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }

  tags = { Name = "TIB-private-rt-1" }
}

resource "aws_route_table" "private_2" { # Private Route Table AZ2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }

  tags = { Name = "TIB-private-rt-2" }
}

# 서브넷과 라우트 테이블 연결
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}