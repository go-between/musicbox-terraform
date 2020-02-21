data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ssm-ssh-management-staging" {
  statement {
    actions = [
      "ec2-instance-connect:SendSSHPublicKey"
    ]
    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.ssm-staging.id}"
    ]
  }
}

resource "aws_iam_policy" "ssm-ssh-management-staging" {
  name   = "ssm-ssh-management-staging"
  path   = "/"
  policy = data.aws_iam_policy_document.ssm-ssh-management-staging.json
}

resource "aws_iam_policy_attachment" "ssm-ssh-management-staging" {
  name       = "ssm-ssh-management-staging"
  users      = ["musicbox-truman"]
  policy_arn = aws_iam_policy.ssm-ssh-management-staging.arn
}
