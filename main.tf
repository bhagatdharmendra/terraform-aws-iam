provider "aws" {
  access_key = var.access_key 
  secret_key = var.secret_key
}
resource "aws_iam_user" "newuser" {
  count = length(var.newuser)
  name = element(var.newuser, count.index)
  path = "/system/"
  force_destroy = true

  tags = {
    Name = element(var.newuser, count.index)
  }
}


resource "aws_iam_access_key" "test" {
  count = length(var.newuser)
  user = element(var.newuser, count.index)
}
resource "aws_iam_user_login_profile" "u" {
  count = length(var.newuser)
  user                    = element(var.newuser, count.index)
  password_reset_required = true
  pgp_key="keybase:terraform_user"
}

resource "aws_iam_policy" "policy" {
  name        = "ec2-full-terraform"
  path        = "/"
  description = "My test policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "ec2:*",
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEquals": {
                    "ec2:Region": "ap-south-1"
                }
            }
        }
    ]
}
  EOF

}
resource "aws_iam_user_policy_attachment" "test-attach" {
  depends_on = [
     aws_iam_policy.policy, aws_iam_access_key.test
  ]
  count = length(var.newuser)
  user       = element(var.newuser, count.index)
  policy_arn = aws_iam_policy.policy.arn
}

output "password" {
value= aws_iam_user_login_profile.u[*].encrypted_password
}