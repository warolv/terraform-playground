# Objective

The challenge should take up to 120 minutes. We respect your time and know you’re busy.

Your task will be to use Terraform with the Terraform AWS provider to write a .tf template
that will set up the following infrastructure when ran:

1. A single t3.micro server running a public AMI of Linux-flavor OS of your choice

2. An ALB that would use this server as target

3. A CNAME Route53 record under a zone named “forter-interview-challenge.com” that
would point to the ALB.
For example: magicpage.forter-interview-challenge.com IN CNAME <ALB address>
NOTE: there’s no need to buy the domain and/or direct it to the AWS NS servers. We
only want to see the record created successfully.

4. The server should be running an Nginx docker container that would respond to one
specific URI: /hello
When a “name” URI parameter is passed (/hello?name=Forter) the page should
respond with HTTP 200 “Hello <name>!” i.e. for the example above - the response
should be “Hello Forter!”. Otherwise an HTTP 400 error should be the response.


## Requirements & Guidelines:

1. Use only the free-tier AWS account resources

2. You may use any additional Terraform providers

3. Keep the security of the setup in mind, try to find a reasonable balance

4. All the parameters that you need to supply to the terraform command will be supplied
through a terraform.tfvars file.
Testing the code:
We’ll be using Terraform v0.12.X (whichever is the latest version) to test your code.
