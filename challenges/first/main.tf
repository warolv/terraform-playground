provider "aws" {
  region = "us-west-2"
}

resource "aws_key_pair" "ec2key" {
  key_name   = "publicKey"
  public_key = "${file(var.public_deploy_key)}"
}

resource "aws_instance" "example" {
  ami                    = "ami-0bc06212a56393ee1"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = "${aws_key_pair.ec2key.key_name}"
  associate_public_ip_address = false
  subnet_id =            "${aws_subnet.private_subnet.id}"

  user_data = <<-EOF
              #!/bin/bash
            
              cat <<EOM > /tmp/default.conf
              server {
                  listen       8080;
                  server_name  localhost;

                  location /hello {
                       default_type 'text/plain';

                       content_by_lua_block {
                          if ngx.var.arg_name then
                              ngx.say("Hello ",ngx.var.arg_name,"!")
                              return
                          else
                              ngx.exit(400)
                          end
                       }
                }
              }
              EOM

              sudo yum install -y docker
              sudo service docker start
              sudo docker run  -p 8080:8080 -v /tmp/default.conf:/etc/nginx/conf.d/default.conf openresty/openresty:centos
              EOF
  
  tags = {
    Name = "nginx"
  }
}

resource "aws_security_group" "instance" {
  name    = "nginx-app-sg"
  vpc_id = "${aws_vpc.myVpc.id}"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


################## ALB #############################
resource "aws_lb_target_group" "my-target-group" {
  health_check {
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "my-test-tg"
  port        = var.server_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${aws_vpc.myVpc.id}"
}

resource "aws_lb" "my-aws-alb" {
  name     = "my-test-alb"
  internal = false

  security_groups = [
    "${aws_security_group.my-alb-sg.id}",
  ]

  subnets = [
    "${aws_subnet.public_subnet.id}",
    "${aws_subnet.private_subnet.id}"
  ]

  tags = {
    Name = "my-test-alb"
  }

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

resource "aws_lb_listener" "my-test-alb-listner" {
  load_balancer_arn = "${aws_lb.my-aws-alb.arn}"
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.my-target-group.arn}"
  }
}

resource "aws_security_group" "my-alb-sg" {
  name   = "my-alb-sg"
  vpc_id = "${aws_vpc.myVpc.id}"
}

resource "aws_security_group_rule" "inbound_http" {
  from_port         = var.alb_port
  protocol          = "tcp"
  security_group_id = "${aws_security_group.my-alb-sg.id}"
  to_port           = var.alb_port
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.my-alb-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb_target_group_attachment" "my-tg-attachment" {
  target_group_arn   = "${aws_lb_target_group.my-target-group.arn}"
  target_id          = "${aws_instance.example.id}"  
  port               = var.server_port
}

################## ROUTE 53 #############################
# resource "aws_route53_zone" "fic" {
#   name = "forter-interview-challenge.com"
# }

# resource "aws_route53_record" "magicpage" {
#   zone_id = "${aws_route53_zone.fic.zone_id}"
#   name = "magicpage.forter-interview-challenge.com"
#   type = "CNAME"
#   ttl = "3000"
#   records = ["${aws_lb.my-aws-alb.dns_name}"]
# }
