# Allow nodes to self-register with Chef Server unattended
# $ aws ssm put-parameter --name "chef/test/chef_validator" --type "SecureString" --overwrite --value "$(cat validator.pem)"

resource "aws_iam_role" "chef_validator" {
  name        = "chef_validator"
  description = "IAM role to allow nodes to get Chef Validator key for Test org"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "chef_validator" {
  name        = "chef_validator"
  description = "IAM policy to allow nodes to get Chef Validator key for Test org"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:Describe*",
                "ssm:Get*",
                "ssm:List*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "chef_validator_attach" {
  role       = "${aws_iam_role.chef_validator.name}"
  policy_arn = "${aws_iam_policy.chef_validator.arn}"
}

resource "aws_iam_instance_profile" "chef_validator" {
  name = "chef_validator"
  role = "${aws_iam_role.chef_validator.name}"
}
