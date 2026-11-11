resource "aws_iam_role" "demo_eks_cluster_role" {
  name = "demo-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "demo_eks_cluster_policy" {
  role = aws_iam_role.demo_eks_cluster_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

}

resource "aws_eks_cluster" "demo_eks_cluster" {
  name = "demo-eks-cluster"

  role_arn = aws_iam_role.demo_eks_cluster_role.arn

  version = "1.35"

  vpc_config {

    subnet_ids = [
      aws_subnet.demo_eks_privatesub1.id,
      aws_subnet.demo_eks_privatesub2.id,
      aws_subnet.demo_eks_privatesub3.id
    ]

    endpoint_private_access = true
    endpoint_public_access  = true
  }



  depends_on = [
    aws_iam_role_policy_attachment.demo_eks_cluster_policy
  ]

}

resource "aws_iam_role" "demo_eks_node_role" {
  name = "demo-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "demo_eks_node_policy" {
  role = aws_iam_role.demo_eks_node_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "demo_eks_cni_policy" {
  role = aws_iam_role.demo_eks_node_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "demo_eks_ecr_policy" {
  role = aws_iam_role.demo_eks_node_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "demo_eks_node_group" {
  cluster_name    = aws_eks_cluster.demo_eks_cluster.name
  node_group_name = "demo-eks-primary-node-group"
  node_role_arn   = aws_iam_role.demo_eks_node_role.arn

  subnet_ids = [
    aws_subnet.demo_eks_privatesub1.id,
    aws_subnet.demo_eks_privatesub2.id,
    aws_subnet.demo_eks_privatesub3.id
  ]

  capacity_type = "SPOT" #ON_DEMAND

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }
  depends_on = [
    aws_iam_role_policy_attachment.demo_eks_node_policy,
    aws_iam_role_policy_attachment.demo_eks_cni_policy,
    aws_iam_role_policy_attachment.demo_eks_ecr_policy
  ]
}